#!/bin/bash
set -e

echo "=== Starting DB Server Setup ==="

# Variables
DB_NAME="lla_db"
DB_USER="lla_user"
DB_PASS="YourSecurePassword123!"
WEB_SERVER_IP="x.x.x.x"  # Replace with your Web Server's public OR private IP

# Update system
echo "Updating packages..."
sudo apt update && sudo apt upgrade -y

# Install MySQL
echo "Installing MySQL..."
sudo apt install -y mysql-server

# Secure MySQL installation (automated)
echo "Securing MySQL installation..."
sudo mysql << EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_PASS}Root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

# Create database and user with RESTRICTED privileges (Least Privilege)
echo "Creating database and restricted user..."
sudo mysql -u root -p"${DB_PASS}Root" << EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME;
CREATE USER IF NOT EXISTS '$DB_USER'@'$WEB_SERVER_IP' IDENTIFIED BY '$DB_PASS';
GRANT SELECT, INSERT, UPDATE ON $DB_NAME.* TO '$DB_USER'@'$WEB_SERVER_IP';
-- LoanHistory needs INSERT for tracking loans
GRANT INSERT, UPDATE ON $DB_NAME.LoanHistory TO '$DB_USER'@'$WEB_SERVER_IP';
FLUSH PRIVILEGES;
EOF

# Configure MySQL to bind to private IP (not localhost only)
PRIVATE_IP=$(hostname -I | awk '{print $1}')
sudo sed -i "s/^bind-address\s*=.*/bind-address = $PRIVATE_IP/" /etc/mysql/mysql.conf.d/mysqld.cnf

# Restart MySQL
sudo systemctl restart mysql

# Create schema (run this after copying schema.sql to server)
# You'll need to transfer schema.sql and seed_data.sql first
# For now, create a placeholder for the schema
cat > /tmp/schema.sql << 'EOF'
-- Database: lla_db
CREATE TABLE IF NOT EXISTS Author (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    UNIQUE KEY uk_author_name (name)
);

CREATE TABLE IF NOT EXISTS Book (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(300) NOT NULL,
    isbn VARCHAR(13) UNIQUE,
    publication_year INT,
    total_copies INT DEFAULT 1,
    available_copies INT DEFAULT 1
);

CREATE TABLE IF NOT EXISTS BookAuthor (
    book_id INT NOT NULL,
    author_id INT NOT NULL,
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id) REFERENCES Book(book_id) ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES Author(author_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Member (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(200) NOT NULL UNIQUE,
    full_name VARCHAR(200) NOT NULL,
    phone VARCHAR(20),
    registration_date DATE DEFAULT (CURDATE())
);

CREATE TABLE IF NOT EXISTS LoanHistory (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    loan_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE NULL,
    FOREIGN KEY (book_id) REFERENCES Book(book_id),
    FOREIGN KEY (member_id) REFERENCES Member(member_id),
    INDEX idx_loan_status (return_date, due_date)
);
EOF

# Apply schema
sudo mysql -u root -p"${DB_PASS}Root" $DB_NAME < /tmp/schema.sql

# Configure firewall (only allow MySQL from Web Server IP)
echo "Configuring firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from $WEB_SERVER_IP to any port 3306 proto tcp
sudo ufw allow 22/tcp  # SSH for admin
echo "y" | sudo ufw enable

echo "=== DB Server Setup Complete ==="
echo "Database '$DB_NAME' created with user '$DB_USER'"
echo "MySQL listening on $PRIVATE_IP:3306"