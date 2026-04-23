-- =============================================================
-- Local Library Archive (LLA) -- Legacy Migration Project
-- Sample Data: seed_data.sql
-- Description: Realistic seed data for testing and demonstration.
--              Run AFTER schema.sql.
--              Safe to re-run: uses INSERT IGNORE to avoid
--              duplicate key errors on repeated runs.
-- =============================================================

USE lla_db;

-- =============================================================
-- Authors
-- =============================================================
INSERT IGNORE INTO Author (author_id, first_name, last_name, nationality, birth_year) VALUES
(1,  'George',    'Orwell',       'British',    1903),
(2,  'Jane',      'Austen',       'British',    1775),
(3,  'Chinua',    'Achebe',       'Nigerian',   1930),
(4,  'Toni',      'Morrison',     'American',   1931),
(5,  'Gabriel',   'Garcia Marquez','Colombian', 1927),
(6,  'Haruki',    'Murakami',     'Japanese',   1949),
(7,  'Virginia',  'Woolf',        'British',    1882),
(8,  'James',     'Baldwin',      'American',   1924),
(9,  'Chimamanda','Ngozi Adichie','Nigerian',   1977),
(10, 'Fyodor',    'Dostoevsky',   'Russian',    1821);


-- =============================================================
-- Books
-- =============================================================
INSERT IGNORE INTO Book (book_id, isbn, title, genre, publisher, publish_year, total_copies) VALUES
(1,  '978-0451524935', 'Nineteen Eighty-Four',           'Dystopian Fiction', 'Secker & Warburg',      1949, 3),
(2,  '978-0141439518', 'Pride and Prejudice',             'Classic Fiction',   'T. Egerton',            1813, 2),
(3,  '978-0385474542', 'Things Fall Apart',               'Literary Fiction',  'Heinemann',             1958, 4),
(4,  '978-1400033416', 'Beloved',                         'Historical Fiction','Alfred A. Knopf',       1987, 2),
(5,  '978-0060883287', 'One Hundred Years of Solitude',   'Magical Realism',   'Harper & Row',          1967, 3),
(6,  '978-0375704024', 'Norwegian Wood',                  'Literary Fiction',  'Kodansha',              1987, 2),
(7,  '978-0156907392', 'Mrs Dalloway',                    'Modernist Fiction', 'Hogarth Press',         1925, 2),
(8,  '978-0679744719', 'Giovanni\'s Room',                'Literary Fiction',  'Dial Press',            1956, 1),
(9,  '978-1616953638', 'Americanah',                      'Contemporary Fiction','Anchor Books',        2013, 3),
(10, '978-0374528379', 'Crime and Punishment',            'Psychological Fiction','The Russian Messenger',1866,2);


-- =============================================================
-- BookAuthor (junction)
-- =============================================================
INSERT IGNORE INTO BookAuthor (book_id, author_id, role) VALUES
(1,  1,  'Author'),
(2,  2,  'Author'),
(3,  3,  'Author'),
(4,  4,  'Author'),
(5,  5,  'Author'),
(6,  6,  'Author'),
(7,  7,  'Author'),
(8,  8,  'Author'),
(9,  9,  'Author'),
(10, 10, 'Author');


-- =============================================================
-- Members
-- =============================================================
INSERT IGNORE INTO Member (member_id, first_name, last_name, email, phone, join_date, is_active) VALUES
(1,  'Alice',   'Thompson',  'a.thompson@email.com',   '07700900001', '2022-03-15', 1),
(2,  'Brian',   'Okafor',    'b.okafor@email.com',     '07700900002', '2022-06-20', 1),
(3,  'Clara',   'Singh',     'c.singh@email.com',      '07700900003', '2023-01-10', 1),
(4,  'David',   'Martinez',  'd.martinez@email.com',   '07700900004', '2023-04-05', 1),
(5,  'Evelyn',  'Chen',      'e.chen@email.com',       '07700900005', '2023-07-22', 1),
(6,  'Frank',   'Mensah',    'f.mensah@email.com',     '07700900006', '2023-09-01', 0),
(7,  'Grace',   'Patel',     'g.patel@email.com',      '07700900007', '2024-01-14', 1),
(8,  'Henry',   'Walker',    'h.walker@email.com',     '07700900008', '2024-02-28', 1),
(9,  'Isla',    'Brown',     'i.brown@email.com',      '07700900009', '2024-05-11', 1),
(10, 'James',   'Kofi',      'j.kofi@email.com',       '07700900010', '2024-08-30', 1);


-- =============================================================
-- LoanHistory
-- Mix of returned loans and currently active loans
-- =============================================================
INSERT IGNORE INTO LoanHistory (loan_id, member_id, book_id, loan_date, due_date, returned_date, renewed_count) VALUES
-- Returned loans
(1,  1, 1, '2024-01-10', '2024-01-24', '2024-01-22', 0),
(2,  2, 3, '2024-02-01', '2024-02-15', '2024-02-14', 0),
(3,  3, 5, '2024-02-20', '2024-03-06', '2024-03-05', 1),
(4,  4, 2, '2024-03-15', '2024-03-29', '2024-03-28', 0),
(5,  5, 7, '2024-04-01', '2024-04-15', '2024-04-12', 0),
(6,  1, 4, '2024-05-10', '2024-05-24', '2024-05-20', 0),
(7,  6, 9, '2024-06-01', '2024-06-15', '2024-06-15', 0),
(8,  7, 6, '2024-07-03', '2024-07-17', '2024-07-16', 0),
-- Currently active loans (returned_date is NULL)
(9,  8, 8,  CURDATE() - INTERVAL 5 DAY,  CURDATE() + INTERVAL 9 DAY,  NULL, 0),
(10, 9, 10, CURDATE() - INTERVAL 3 DAY,  CURDATE() + INTERVAL 11 DAY, NULL, 0),
(11, 10, 1, CURDATE() - INTERVAL 1 DAY,  CURDATE() + INTERVAL 13 DAY, NULL, 0),
-- Overdue loan
(12, 3, 2,  CURDATE() - INTERVAL 20 DAY, CURDATE() - INTERVAL 6 DAY,  NULL, 1);
