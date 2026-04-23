#!/bin/bash
set -e

echo "=== WEB SERVER SETUP STARTING ==="

# Your DB server private IP
DB_PRIVATE_IP="172.31.29.175"
DB_NAME="lla_db"
DB_USER="lla_user"
DB_PASS="LibrarySecure2026!"

# Update system
sudo apt update -y

# Install Apache and PHP
sudo apt install -y apache2 php libapache2-mod-php php-mysql

# Start Apache
sudo systemctl enable apache2
sudo systemctl start apache2

# Create the search interface directory
sudo mkdir -p /var/www/html/lla

# Create config.php
sudo tee /var/www/html/lla/config.php > /dev/null << 'EOF'
<?php
$host = '172.31.29.175';
$dbname = 'lla_db';
$user = 'lla_user';
$pass = 'LibrarySecure2026!';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    die("Connection failed: " . $e->getMessage());
}
?>
EOF

# Create index.php search page
sudo tee /var/www/html/lla/index.php > /dev/null << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>LLA Library Search</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 900px; margin: auto; background: white; padding: 20px; border-radius: 10px; }
        input, button { padding: 10px; margin: 5px; font-size: 16px; }
        input { width: 300px; }
        button { background: #4CAF50; color: white; border: none; cursor: pointer; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
        th { background: #4CAF50; color: white; }
        .available { color: green; font-weight: bold; }
        .borrowed { color: red; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📚 Local Library Archive</h1>
        <form method="GET">
            <input type="text" name="search" placeholder="Search by title or author..." required>
            <button type="submit">🔍 Search</button>
        </form>
        <?php
        require_once 'config.php';
        
        if(isset($_GET['search']) && !empty($_GET['search'])) {
            $search = '%' . $_GET['search'] . '%';
            $stmt = $pdo->prepare("
                SELECT DISTINCT b.title, a.name as author, b.publication_year,
                CASE WHEN l.return_date IS NULL AND l.loan_id IS NOT NULL THEN 'Borrowed' ELSE 'Available' END as status
                FROM Book b
                LEFT JOIN BookAuthor ba ON b.book_id = ba.book_id
                LEFT JOIN Author a ON ba.author_id = a.author_id
                LEFT JOIN LoanHistory l ON b.book_id = l.book_id AND l.return_date IS NULL
                WHERE b.title LIKE ? OR a.name LIKE ?
                LIMIT 50
            ");
            $stmt->execute([$search, $search]);
            $results = $stmt->fetchAll();
            
            if(count($results) > 0) {
                echo "<h3>Found " . count($results) . " results:</h3>";
                echo "<table>";
                echo "<tr><th>Title</th><th>Author</th><th>Year</th><th>Status</th></tr>";
                foreach($results as $row) {
                    echo "<tr>";
                    echo "<td>" . htmlspecialchars($row['title']) . "</td>";
                    echo "<td>" . htmlspecialchars($row['author']) . "</td>";
                    echo "<td>" . htmlspecialchars($row['publication_year']) . "</td>";
                    $status_class = ($row['status'] == 'Available') ? 'available' : 'borrowed';
                    echo "<td class='$status_class'>" . htmlspecialchars($row['status']) . "</td>";
                    echo "</tr>";
                }
                echo "</table>";
            } else {
                echo "<p>❌ No books found matching your search.</p>";
            }
        }
        ?>
    </div>
</body>
</html>
EOF

# Configure firewall
sudo ufw --force enable
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Set permissions
sudo chown -R www-data:www-data /var/www/html/lla
sudo chmod -R 755 /var/www/html/lla

# Restart Apache
sudo systemctl restart apache2

echo "=== WEB SERVER READY ==="
echo "Access your site at: http://34.228.58.26/lla/"