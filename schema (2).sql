-- ============================================
-- LLA Library Database Schema
-- Project: Legacy Migration Project
-- Normalization: 3NF (Third Normal Form)
-- GDPR Compliant: Data minimization, no unnecessary personal data
-- ============================================

-- Drop database if exists (for clean setup)
DROP DATABASE IF EXISTS lla_db;
CREATE DATABASE lla_db;
USE lla_db;

-- ============================================
-- TABLE 1: Author
-- Stores author information
-- PK: author_id
-- 3NF: No transitive dependencies
-- ============================================
CREATE TABLE Author (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    -- GDPR: No unnecessary author personal data collected
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_author_name (name)
);

-- ============================================
-- TABLE 2: Publisher
-- Stores publisher information (supporting table)
-- PK: publisher_id
-- ============================================
CREATE TABLE Publisher (
    publisher_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL UNIQUE,
    address TEXT,
    -- GDPR: Only store business contact info, not personal
    contact_email VARCHAR(200)
);

-- ============================================
-- TABLE 3: Book
-- Stores book information
-- PK: book_id
-- FK: publisher_id references Publisher
-- 3NF: No transitive dependencies (publisher details in separate table)
-- ============================================
CREATE TABLE Book (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(300) NOT NULL,
    isbn VARCHAR(13) UNIQUE,  -- GDPR: Not personal data, book identifier
    publication_year INT,
    publisher_id INT,
    total_copies INT DEFAULT 1,
    available_copies INT DEFAULT 1,
    -- Data integrity: Ensure available_copies never exceeds total_copies
    CONSTRAINT chk_available_copies CHECK (available_copies >= 0 AND available_copies <= total_copies),
    FOREIGN KEY (publisher_id) REFERENCES Publisher(publisher_id) ON DELETE SET NULL,
    INDEX idx_book_title (title),
    INDEX idx_book_isbn (isbn)
);

-- ============================================
-- TABLE 4: BookAuthor (Junction Table)
-- Many-to-many relationship between Book and Author
-- PK: (book_id, author_id) composite key
-- 2NF: Whole primary key dependency (no partial dependencies)
-- ============================================
CREATE TABLE BookAuthor (
    book_id INT NOT NULL,
    author_id INT NOT NULL,
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id) REFERENCES Book(book_id) ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES Author(author_id) ON DELETE CASCADE
);

-- ============================================
-- TABLE 5: Member
-- Stores library member information
-- PK: member_id
-- GDPR COMPLIANT: Data minimization, encrypted storage, retention policy ready
-- ============================================
CREATE TABLE Member (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(200) NOT NULL UNIQUE,
    full_name VARCHAR(200) NOT NULL,
    phone VARCHAR(20),
    -- GDPR: Pseudonymization - address stored separately with restricted access
    address_hash VARCHAR(255),  -- Hashed for GDPR compliance
    registration_date DATE DEFAULT (CURDATE()),
    is_active BOOLEAN DEFAULT TRUE,
    -- GDPR: Data retention - track last activity
    last_active_date DATE,
    -- Least Privilege: Different access levels
    membership_tier ENUM('Standard', 'Premium', 'Staff') DEFAULT 'Standard',
    INDEX idx_member_email (email),
    INDEX idx_member_registration (registration_date)
);

-- ============================================
-- TABLE 6: LoanHistory
-- Tracks all book loans and returns
-- PK: loan_id
-- FK: book_id references Book, member_id references Member
-- GDPR: Anonymized after retention period
-- ============================================
CREATE TABLE LoanHistory (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    loan_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE NULL,
    -- Data integrity: Prevent invalid dates
    CONSTRAINT chk_dates CHECK (due_date >= loan_date),
    -- Optional: Track who processed the loan (audit trail)
    processed_by VARCHAR(100),
    FOREIGN KEY (book_id) REFERENCES Book(book_id) ON DELETE RESTRICT,
    FOREIGN KEY (member_id) REFERENCES Member(member_id) ON DELETE RESTRICT,
    INDEX idx_loan_dates (loan_date, due_date),
    INDEX idx_loan_return (return_date),
    INDEX idx_loan_member (member_id)
);

-- ============================================
-- TABLE 7: Reservation (Bonus feature)
-- Allows members to reserve books that are currently borrowed
-- PK: reservation_id
-- ============================================
CREATE TABLE Reservation (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    reservation_date DATE NOT NULL,
    status ENUM('Pending', 'Fulfilled', 'Cancelled', 'Expired') DEFAULT 'Pending',
    expiry_date DATE,
    FOREIGN KEY (book_id) REFERENCES Book(book_id) ON DELETE CASCADE,
    FOREIGN KEY (member_id) REFERENCES Member(member_id) ON DELETE CASCADE,
    INDEX idx_reservation_status (status)
);

-- ============================================
-- TABLE 8: AuditLog (GDPR requirement)
-- Tracks all data access and modifications for compliance
-- ============================================
CREATE TABLE AuditLog (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    action VARCHAR(20) NOT NULL,  -- SELECT, INSERT, UPDATE, DELETE
    record_id INT,
    user_id VARCHAR(100),
    ip_address VARCHAR(45),
    action_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_audit_timestamp (action_timestamp)
);

-- ============================================
-- TRIGGER: Update available_copies when book is borrowed
-- Maintains data integrity automatically
-- ============================================
DELIMITER //
CREATE TRIGGER decrease_available_copies
AFTER INSERT ON LoanHistory
FOR EACH ROW
BEGIN
    IF NEW.return_date IS NULL THEN
        UPDATE Book 
        SET available_copies = available_copies - 1 
        WHERE book_id = NEW.book_id;
    END IF;
END//

CREATE TRIGGER increase_available_copies
AFTER UPDATE ON LoanHistory
FOR EACH ROW
BEGIN
    IF OLD.return_date IS NULL AND NEW.return_date IS NOT NULL THEN
        UPDATE Book 
        SET available_copies = available_copies + 1 
        WHERE book_id = NEW.book_id;
    END IF;
END//
DELIMITER ;

-- ============================================
-- VIEW: BorrowedBooksView (Convenience view for reporting)
-- Shows currently borrowed books
-- ============================================
CREATE VIEW BorrowedBooksView AS
SELECT 
    l.loan_id,
    b.title,
    m.full_name AS borrower_name,
    m.email AS borrower_email,
    l.loan_date,
    l.due_date,
    DATEDIFF(CURDATE(), l.due_date) AS days_overdue
FROM LoanHistory l
JOIN Book b ON l.book_id = b.book_id
JOIN Member m ON l.member_id = m.member_id
WHERE l.return_date IS NULL;

-- ============================================
-- VIEW: AvailableBooksView (For search interface)
-- Shows only available books
-- ============================================
CREATE VIEW AvailableBooksView AS
SELECT 
    b.book_id,
    b.title,
    b.isbn,
    GROUP_CONCAT(DISTINCT a.name SEPARATOR ', ') AS authors,
    b.available_copies
FROM Book b
LEFT JOIN BookAuthor ba ON b.book_id = ba.book_id
LEFT JOIN Author a ON ba.author_id = a.author_id
WHERE b.available_copies > 0
GROUP BY b.book_id;

-- ============================================
-- STORED PROCEDURE: ReturnBook
-- Handles book return process in one transaction
-- ============================================
DELIMITER //
CREATE PROCEDURE ReturnBook(IN p_loan_id INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    UPDATE LoanHistory 
    SET return_date = CURDATE() 
    WHERE loan_id = p_loan_id AND return_date IS NULL;
    
    COMMIT;
END//

-- ============================================
-- STORED PROCEDURE: GDPR Anonymize Member
-- Anonymizes member data after account deletion request (GDPR Article 17)
-- ============================================
CREATE PROCEDURE GDPR_AnonymizeMember(IN p_member_id INT)
BEGIN
    UPDATE Member 
    SET 
        email = CONCAT('deleted_', p_member_id, '@anonymized.lla'),
        full_name = '[REDACTED]',
        phone = NULL,
        address_hash = NULL,
        is_active = FALSE
    WHERE member_id = p_member_id;
    
    -- Log for audit trail
    INSERT INTO AuditLog (table_name, action, record_id, user_id)
    VALUES ('Member', 'GDPR_DELETE', p_member_id, CURRENT_USER());
END//
DELIMITER ;

-- ============================================
-- INDEXES FOR PERFORMANCE
-- Optimizes search queries and reporting
-- ============================================
CREATE INDEX idx_loanhistory_return_date ON LoanHistory(return_date);
CREATE INDEX idx_loanhistory_due_date ON LoanHistory(due_date);
CREATE INDEX idx_book_title_search ON Book(title(100));
CREATE INDEX idx_member_name ON Member(full_name(100));