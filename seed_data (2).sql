-- ============================================
-- LLA Library Sample Data
-- Populates the database with realistic test data
-- ============================================

USE lla_db;

-- ============================================
-- Insert Publishers
-- ============================================
INSERT INTO Publisher (name, address, contact_email) VALUES
('Penguin Random House', '1745 Broadway, New York, NY 10019', 'contact@penguinrandomhouse.com'),
('HarperCollins', '195 Broadway, New York, NY 10007', 'info@harpercollins.com'),
('Oxford University Press', 'Great Clarendon Street, Oxford OX2 6DP', 'academic@oup.com'),
('Cambridge University Press', 'University Printing House, Cambridge CB2 8BS', 'press@cambridge.org'),
('Simon & Schuster', '1230 Avenue of the Americas, New York, NY 10020', 'enquiries@simonandschuster.com');

-- ============================================
-- Insert Authors
-- ============================================
INSERT INTO Author (name) VALUES
('George Orwell'),
('Jane Austen'),
('J.K. Rowling'),
('J.R.R. Tolkien'),
('F. Scott Fitzgerald'),
('Harper Lee'),
('Ernest Hemingway'),
('Charles Dickens'),
('Mark Twain'),
('Virginia Woolf'),
('Stephen King'),
('Agatha Christie'),
('Arthur Conan Doyle'),
('Ray Bradbury'),
('Aldous Huxley');

-- ============================================
-- Insert Books
-- ============================================
INSERT INTO Book (title, isbn, publication_year, publisher_id, total_copies, available_copies) VALUES
-- Classic Literature
('1984', '9780451524935', 1949, 1, 5, 3),
('Pride and Prejudice', '9780141439518', 1813, 2, 4, 4),
('Harry Potter and the Philosopher''s Stone', '9780747532699', 1997, 5, 8, 5),
('The Hobbit', '9780547928227', 1937, 1, 6, 4),
('The Great Gatsby', '9780743273565', 1925, 5, 4, 3),
('To Kill a Mockingbird', '9780061120084', 1960, 2, 5, 4),
('The Old Man and the Sea', '9780684801223', 1952, 5, 3, 2),
('A Tale of Two Cities', '9780141439600', 1859, 3, 4, 4),
('The Adventures of Tom Sawyer', '9780141321103', 1876, 2, 3, 2),
('Mrs Dalloway', '9780156628709', 1925, 4, 2, 2),

-- Modern Fiction
('The Shining', '9780307743657', 1977, 1, 4, 3),
('Murder on the Orient Express', '9780062693662', 1934, 2, 3, 2),
('The Hound of the Baskervilles', '9780140437867', 1902, 2, 3, 3),
('Fahrenheit 451', '9781451673319', 1953, 5, 4, 3),
('Brave New World', '9780060850524', 1932, 2, 4, 3);

-- ============================================
-- Link Books to Authors (BookAuthor junction table)
-- ============================================
INSERT INTO BookAuthor (book_id, author_id) VALUES
(1, 1),   -- 1984 by Orwell
(2, 2),   -- Pride and Prejudice by Austen
(3, 3),   -- Harry Potter by Rowling
(4, 4),   -- The Hobbit by Tolkien
(5, 5),   -- Great Gatsby by Fitzgerald
(6, 6),   -- To Kill a Mockingbird by Lee
(7, 7),   -- Old Man and the Sea by Hemingway
(8, 8),   -- Tale of Two Cities by Dickens
(9, 9),   -- Tom Sawyer by Twain
(10, 10), -- Mrs Dalloway by Woolf
(11, 11), -- The Shining by King
(12, 12), -- Murder on Orient Express by Christie
(13, 13), -- Hound of Baskervilles by Doyle
(14, 14), -- Fahrenheit 451 by Bradbury
(15, 15); -- Brave New World by Huxley

-- ============================================
-- Insert Members (GDPR compliant - minimal personal data)
-- ============================================
INSERT INTO Member (email, full_name, phone, registration_date, membership_tier, is_active) VALUES
('emma.wilson@email.com', 'Emma Wilson', '+44 7700 123456', '2024-01-15', 'Premium', TRUE),
('james.brown@email.com', 'James Brown', '+44 7700 234567', '2024-02-20', 'Standard', TRUE),
('sophia.davis@email.com', 'Sophia Davis', '+44 7700 345678', '2024-03-10', 'Premium', TRUE),
('liam.martinez@email.com', 'Liam Martinez', '+44 7700 456789', '2024-04-05', 'Standard', TRUE),
('olivia.garcia@email.com', 'Olivia Garcia', '+44 7700 567890', '2024-05-12', 'Staff', TRUE),
('noah.rodriguez@email.com', 'Noah Rodriguez', '+44 7700 678901', '2024-06-18', 'Standard', TRUE),
('ava.wilson@email.com', 'Ava Wilson', '+44 7700 789012', '2024-07-22', 'Premium', TRUE),
('mason.anderson@email.com', 'Mason Anderson', '+44 7700 890123', '2024-08-30', 'Standard', TRUE),
('isabella.thomas@email.com', 'Isabella Thomas', '+44 7700 901234', '2024-09-14', 'Standard', TRUE),
('ethan.jackson@email.com', 'Ethan Jackson', '+44 7700 012345', '2024-10-25', 'Premium', TRUE),

-- Some inactive members (for GDPR testing)
('old.member@email.com', 'Old Member', '+44 7700 999999', '2023-01-01', 'Standard', FALSE),
('inactive@email.com', 'Inactive User', '+44 7700 888888', '2023-06-15', 'Standard', FALSE);

-- ============================================
-- Insert Loan History (Current and past loans)
-- ============================================

-- Current active loans (return_date IS NULL)
INSERT INTO LoanHistory (book_id, member_id, loan_date, due_date, return_date, processed_by) VALUES
(1, 1, '2026-04-10', '2026-04-24', NULL, 'librarian@lla.org'),
(3, 2, '2026-04-11', '2026-04-25', NULL, 'librarian@lla.org'),
(5, 3, '2026-04-09', '2026-04-23', NULL, 'librarian@lla.org'),
(7, 4, '2026-04-12', '2026-04-26', NULL, 'librarian@lla.org'),
(11, 5, '2026-04-08', '2026-04-22', NULL, 'librarian@lla.org'),
(14, 6, '2026-04-13', '2026-04-27', NULL, 'librarian@lla.org'),
(2, 7, '2026-04-10', '2026-04-24', NULL, 'librarian@lla.org'),
(8, 8, '2026-04-11', '2026-04-25', NULL, 'librarian@lla.org');

-- Past loans (returned)
INSERT INTO LoanHistory (book_id, member_id, loan_date, due_date, return_date, processed_by) VALUES
(2, 1, '2026-03-01', '2026-03-15', '2026-03-14', 'librarian@lla.org'),
(4, 2, '2026-03-05', '2026-03-19', '2026-03-18', 'librarian@lla.org'),
(6, 3, '2026-03-10', '2026-03-24', '2026-03-22', 'librarian@lla.org'),
(9, 4, '2026-03-15', '2026-03-29', '2026-03-28', 'librarian@lla.org'),
(12, 5, '2026-03-20', '2026-04-03', '2026-04-02', 'librarian@lla.org'),
(13, 6, '2026-03-25', '2026-04-08', '2026-04-07', 'librarian@lla.org'),
(15, 7, '2026-03-28', '2026-04-11', '2026-04-10', 'librarian@lla.org'),
(1, 8, '2026-02-01', '2026-02-15', '2026-02-14', 'librarian@lla.org'),
(3, 9, '2026-02-10', '2026-02-24', '2026-02-23', 'librarian@lla.org'),
(5, 10, '2026-02-15', '2026-02-29', '2026-02-28', 'librarian@lla.org');

-- ============================================
-- Insert Reservations
-- ============================================
INSERT INTO Reservation (book_id, member_id, reservation_date, status, expiry_date) VALUES
(1, 2, '2026-04-15', 'Pending', '2026-04-29'),
(3, 4, '2026-04-14', 'Pending', '2026-04-28'),
(5, 6, '2026-04-13', 'Fulfilled', '2026-04-27'),
(7, 8, '2026-04-12', 'Cancelled', '2026-04-26');

-- ============================================
-- Insert Audit Log entries (GDPR compliance)
-- ============================================
INSERT INTO AuditLog (table_name, action, record_id, user_id, ip_address) VALUES
('Member', 'SELECT', 1, 'librarian@lla.org', '192.168.1.100'),
('LoanHistory', 'INSERT', 21, 'librarian@lla.org', '192.168.1.101'),
('Book', 'UPDATE', 1, 'system', '127.0.0.1');

-- ============================================
-- Verify data was inserted correctly
-- ============================================
SELECT '=== DATABASE POPULATED ===' AS Status;
SELECT COUNT(*) AS Total_Books FROM Book;
SELECT COUNT(*) AS Total_Authors FROM Author;
SELECT COUNT(*) AS Total_Members FROM Member;
SELECT COUNT(*) AS Total_Loans FROM LoanHistory;
SELECT COUNT(*) AS Active_Loans FROM LoanHistory WHERE return_date IS NULL;

-- ============================================
-- Show summary of current library status
-- ============================================
SELECT 
    'Library Status Summary' AS Report,
    (SELECT COUNT(*) FROM Book) AS Total_Titles,
    (SELECT SUM(available_copies) FROM Book) AS Available_Copies,
    (SELECT COUNT(*) FROM LoanHistory WHERE return_date IS NULL) AS Currently_Borrowed,
    (SELECT COUNT(*) FROM Member WHERE is_active = TRUE) AS Active_Members;