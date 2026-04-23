-- =============================================================
-- Local Library Archive (LLA) -- Legacy Migration Project
-- Database Schema: schema.sql
-- Module: 5COM2006 Design and Configuration Project
-- Team: Data Dwellers
-- Description: 3NF normalised schema for the LLA digital
--              catalogue system. Stores books, authors, members,
--              and loan history. Designed with GDPR compliance
--              and data integrity as core principles.
-- =============================================================

-- Drop and recreate the database cleanly
DROP DATABASE IF EXISTS lla_db;
CREATE DATABASE lla_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE lla_db;

-- =============================================================
-- TABLE: Author
-- Stores individual author records independently of books.
-- Separating authors from books achieves 3NF: author details
-- (name, nationality) depend only on author_id, not on any
-- book attribute.
-- =============================================================
CREATE TABLE Author (
    author_id     INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    first_name    VARCHAR(100)    NOT NULL,
    last_name     VARCHAR(100)    NOT NULL,
    nationality   VARCHAR(100)    DEFAULT NULL,
    birth_year    YEAR            DEFAULT NULL,
    created_at    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_author PRIMARY KEY (author_id)
) ENGINE=InnoDB;


-- =============================================================
-- TABLE: Book
-- Stores a single record per physical/digital title.
-- isbn is unique to prevent duplicate entries (key challenge).
-- genre and publisher are stored here as atomic values (1NF).
-- No author data here -- that lives in BookAuthor (junction).
-- =============================================================
CREATE TABLE Book (
    book_id       INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    isbn          VARCHAR(20)     NOT NULL,
    title         VARCHAR(255)    NOT NULL,
    genre         VARCHAR(100)    DEFAULT NULL,
    publisher     VARCHAR(150)    DEFAULT NULL,
    publish_year  YEAR            DEFAULT NULL,
    total_copies  TINYINT UNSIGNED NOT NULL DEFAULT 1,
    created_at    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_book      PRIMARY KEY (book_id),
    CONSTRAINT uq_book_isbn UNIQUE      (isbn)
) ENGINE=InnoDB;


-- =============================================================
-- TABLE: BookAuthor  (junction / associative table)
-- Resolves the many-to-many relationship between Book and Author.
-- A book can have multiple authors; an author can write many books.
-- Removing this into a junction table satisfies 2NF -- no partial
-- dependencies on a composite key.
-- =============================================================
CREATE TABLE BookAuthor (
    book_id       INT UNSIGNED    NOT NULL,
    author_id     INT UNSIGNED    NOT NULL,
    role          VARCHAR(50)     NOT NULL DEFAULT 'Author',
                                  -- e.g. 'Author', 'Editor', 'Translator'

    CONSTRAINT pk_bookauthor     PRIMARY KEY (book_id, author_id),
    CONSTRAINT fk_ba_book        FOREIGN KEY (book_id)
        REFERENCES Book(book_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ba_author      FOREIGN KEY (author_id)
        REFERENCES Author(author_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;


-- =============================================================
-- TABLE: Member
-- Stores library member records (GDPR-relevant table).
-- email is unique to prevent duplicate member registrations.
-- GDPR Article 5: only the minimum data necessary is collected.
-- Passwords are NOT stored here -- authentication is handled
-- at the application layer with hashed credentials.
-- =============================================================
CREATE TABLE Member (
    member_id     INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    first_name    VARCHAR(100)    NOT NULL,
    last_name     VARCHAR(100)    NOT NULL,
    email         VARCHAR(255)    NOT NULL,
    phone         VARCHAR(20)     DEFAULT NULL,
    address       TEXT            DEFAULT NULL,
    join_date     DATE            NOT NULL DEFAULT (CURRENT_DATE),
    is_active     TINYINT(1)      NOT NULL DEFAULT 1,
                                  -- 0 = suspended/left, 1 = active
    created_at    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
                                  ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_member         PRIMARY KEY (member_id),
    CONSTRAINT uq_member_email   UNIQUE      (email)
) ENGINE=InnoDB;


-- =============================================================
-- TABLE: LoanHistory
-- Records every book loan transaction.
-- Each row is one loan event: one member borrows one book copy.
-- returned_date NULL means the book is currently on loan.
-- This table satisfies 3NF: all non-key columns (loan_date,
-- due_date, returned_date) depend solely on loan_id, not on
-- member or book attributes.
-- =============================================================
CREATE TABLE LoanHistory (
    loan_id         INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    member_id       INT UNSIGNED    NOT NULL,
    book_id         INT UNSIGNED    NOT NULL,
    loan_date       DATE            NOT NULL DEFAULT (CURRENT_DATE),
    due_date        DATE            NOT NULL,
    returned_date   DATE            DEFAULT NULL,
                                    -- NULL = currently on loan
    renewed_count   TINYINT UNSIGNED NOT NULL DEFAULT 0,

    CONSTRAINT pk_loan           PRIMARY KEY (loan_id),
    CONSTRAINT fk_loan_member    FOREIGN KEY (member_id)
        REFERENCES Member(member_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_loan_book      FOREIGN KEY (book_id)
        REFERENCES Book(book_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    -- A member should not have two active loans of the same book
    CONSTRAINT uq_active_loan    UNIQUE (member_id, book_id, returned_date)
) ENGINE=InnoDB;


-- =============================================================
-- INDEXES
-- Additional indexes on frequently queried foreign keys and
-- search columns to support the web search interface.
-- =============================================================

-- Speed up book title searches
CREATE INDEX idx_book_title      ON Book(title);

-- Speed up loan lookups by member and by return status
CREATE INDEX idx_loan_member     ON LoanHistory(member_id);
CREATE INDEX idx_loan_book       ON LoanHistory(book_id);
CREATE INDEX idx_loan_returned   ON LoanHistory(returned_date);

-- Speed up author name searches
CREATE INDEX idx_author_lastname ON Author(last_name);


-- =============================================================
-- RESTRICTED APPLICATION USER
-- Principle of Least Privilege: the web application connects
-- as lla_user, not as root. lla_user has only the permissions
-- it needs to serve the search interface and record loans.
-- Run this section as root on the DB server after schema creation.
-- Replace 'WEB_SERVER_PRIVATE_IP' with the actual EC2 private IP.
-- =============================================================

-- CREATE USER 'lla_user'@'WEB_SERVER_PRIVATE_IP'
--     IDENTIFIED BY 'CHANGE_THIS_STRONG_PASSWORD';

-- GRANT SELECT, INSERT, UPDATE ON lla_db.Book         TO 'lla_user'@'WEB_SERVER_PRIVATE_IP';
-- GRANT SELECT, INSERT, UPDATE ON lla_db.Author       TO 'lla_user'@'WEB_SERVER_PRIVATE_IP';
-- GRANT SELECT, INSERT, UPDATE ON lla_db.BookAuthor   TO 'lla_user'@'WEB_SERVER_PRIVATE_IP';
-- GRANT SELECT, INSERT, UPDATE ON lla_db.Member       TO 'lla_user'@'WEB_SERVER_PRIVATE_IP';
-- GRANT SELECT, INSERT, UPDATE ON lla_db.LoanHistory  TO 'lla_user'@'WEB_SERVER_PRIVATE_IP';

-- FLUSH PRIVILEGES;

-- NOTE: DELETE is deliberately excluded. Soft-deletion via
-- is_active flag on Member and NULL returned_date on loans
-- is used instead, preserving audit history (GDPR Article 5(e)).
