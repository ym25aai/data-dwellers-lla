#!/bin/bash
set -e  # Stop on error

echo "=== Starting Web Server Setup ==="

# Variables - CHANGE THESE TO MATCH YOUR DB SERVER
DB_PRIVATE_IP="172.31.29.175"
DB_NAME="lla_db"
DB_USER="lla_user"
DB_PASS="12345678"

# Update system
echo "Updating packages..."
sudo apt update && sudo apt upgrade -y

# Install Apache, PHP, and required modules
echo "Installing Apache and PHP..."
sudo apt install -y apache2 php libapache2-mod-php php-mysql php-curl php-json

# Enable Apache modules
echo "Configuring Apache..."
sudo a2enmod rewrite
sudo systemctl enable apache2
sudo systemctl restart apache2

# Create search interface (PHP)
echo "Creating search interface..."
sudo mkdir -p /var/www/html/lla

# Create database connection config
sudo tee /var/www/html/lla/config.php > /dev/null << 'EOF'
<?php
$db_host = getenv('DB_HOST') ?: 'localhost';
$db_name = getenv('DB_NAME') ?: 'lla_db';
$db_user = getenv('DB_USER') ?: 'lla_user';
$db_pass = getenv('DB_PASS') ?: '';

try {
    $pdo = new PDO("mysql:host=$db_host;dbname=$db_name;charset=utf8", $db_user, $db_pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch(PDOException $e) {
    die("Database connection failed: " . $e->getMessage());
}
?>
EOF

# Create search page
sudo tee /var/www/html/lla/index.php > /dev/null << 'EOF'
<!DOCTYPE html>
<html>
<head><title>LLA - Library Search</title><style>
body { font-family: Arial; margin: 40px; }
input, button { padding: 8px; margin: 5px; }
table { border-collapse: collapse; width: 100%; margin-top: 20px; }
th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
th { background-color: #4CAF50; color: white; }
</style></head>
<body>
<h1>Local Library Archive - Search</h1>
<form method="GET">
    <input type="text" name="search" placeholder="Search by title, author, or member..." size="40">
    <button type="submit">Search</button>
</form>

<?php
require_once 'config.php';

if (isset($_GET['search']) && !empty(trim($_GET['search']))) {
    $search = '%' . trim($_GET['search']) . '%';
    
    $sql = "SELECT b.title, a.name as author, b.publication_year, 
                   CASE WHEN l.status = 'borrowed' THEN 'Borrowed' ELSE 'Available' END as status
            FROM Book b
            LEFT JOIN BookAuthor ba ON b.book_id = ba.book_id
            LEFT JOIN Author a ON ba.author_id = a.author_id
            LEFT JOIN LoanHistory l ON b.book_id = l.book_id AND l.return_date IS NULL
            WHERE b.title LIKE ? OR a.name LIKE ?
            GROUP BY b.book_id";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$search, $search]);
    $results = $stmt->fetchAll();
    
    if (count($results) > 0) {
        echo "<h3>Results (" . count($results) . " found)</h3>";
        echo "<table><tr><th>Title</th><th>Author</th><th>Year</th><th>Status</th></tr>";
        foreach ($results as $row) {
            echo "<tr>";
            echo "<td>" . htmlspecialchars($row['title']) . "</td>";
            echo "<td>" . htmlspecialchars($row['author']) . "</td>";
            echo "<td>" . htmlspecialchars($row['publication_year']) . "</td>";
            echo "<td>" . htmlspecialchars($row['status']) . "</td>";
            echo "</tr>";
        }
        echo "</table>";
    } else {
        echo "<p>No results found.</p>";
    }
}
?>
</body></html>
EOF

# Set environment variables for DB connection
echo "DB_HOST=$DB_PRIVATE_IP" | sudo tee -a /etc/environment
echo "DB_NAME=$DB_NAME" | sudo tee -a /etc/environment
echo "DB_USER=$DB_USER" | sudo tee -a /etc/environment
echo "DB_PASS=$DB_PASS" | sudo tee -a /etc/environment

# Configure firewall (UFW)
echo "Configuring firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
echo "y" | sudo ufw enable

# Security hardening: Hide Apache version
echo "ServerTokens Prod" | sudo tee -a /etc/apache2/conf-available/security.conf
echo "ServerSignature Off" | sudo tee -a /etc/apache2/conf-available/security.conf
sudo a2enconf security
sudo systemctl restart apache2

# Set permissions
sudo chown -R www-data:www-data /var/www/html/lla
sudo chmod -R 755 /var/www/html/lla

echo "=== Web Server Setup Complete ==="
echo "Visit http://$(curl -s ifconfig.me)/lla/ to test"