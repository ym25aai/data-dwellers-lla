# data-dwellers-lla
LLA Legacy Migration Project - Deployment Guide
Project: Local Library Archive (LLA) Digital Catalogue System
Version: 1.0
Last Updated: [Date]
Team: [Team Name]

Table of Contents
Overview

Architecture

Prerequisites

Quick Deployment

Manual Deployment

Verification Steps

Maintenance

Troubleshooting

File Reference

Overview
This deployment guide provides instructions for installing and configuring the LLA Legacy Migration digital catalogue system. The system consists of a web server hosting a PHP search interface and a database server storing library records. Both servers run on Ubuntu 22.04 LTS.

Key Features:

Normalised SQL database in Third Normal Form (3NF)

Web-based search interface for books by title or author

Automated daily backups with 30-day retention

GDPR-compliant data handling with anonymisation procedures

Firewall-restricted database access implementing least privilege

Architecture
The system implements a three-tier architecture:

text
Internet → [Firewall:80,443] → Web Server (Public Subnet)
                                    ↓
                            [Firewall:3306]
                                    ↓
                      Database Server (Private Subnet)
Component	IP Address	Subnet	Open Ports
Web Server	34.228.58.26	Public	22 (SSH), 80 (HTTP), 443 (HTTPS)
Database Server	172.31.29.175	Private	22 (SSH), 3306 (MySQL - Web Server only)
Prerequisites
Before beginning deployment, ensure you have the following:

AWS Infrastructure
Requirement	Specification
EC2 Instance 1 (Web Server)	Ubuntu 22.04 LTS, t2.micro, Public IP
EC2 Instance 2 (Database Server)	Ubuntu 22.04 LTS, t2.micro, Private IP only
Security Group (Web)	SSH (22) from admin IP, HTTP (80) from 0.0.0.0/0, HTTPS (443) from 0.0.0.0/0
Security Group (DB)	SSH (22) from admin IP, MySQL (3306) from Web Server IP only
Key Pair	.pem file for SSH access to both instances
Local Machine Requirements
SSH client (terminal on Mac/Linux, PuTTY or WSL on Windows)

Git installed

Access to the project repository

Network Connectivity
Admin machine must have internet access

Admin IP address must be allowed in both security groups (port 22)

Quick Deployment
The system can be deployed automatically using the provided deploy.sh script. This script copies all configuration files to both servers and executes the setup scripts remotely.

Step 1: Clone the Repository
bash
git clone [your-repository-url]
cd [repository-name]
Step 2: Configure Variables
Open deploy.sh and update the following variables:

bash
WEB_IP="34.228.58.26"           # Your web server public IP
DB_IP="172.31.29.175"           # Your database server private IP
KEY_PATH="/path/to/your-key.pem" # Path to your AWS .pem key file
Step 3: Make Scripts Executable
bash
chmod +x deploy.sh
chmod +x setup_web.sh
chmod +x setup_db.sh
chmod +x backup.sh
chmod +x rotate_logs.sh
Step 4: Run Deployment
bash
./deploy.sh
The deployment script will:

Copy setup_db.sh to the database server and execute it

Copy setup_web.sh to the web server and execute it

Copy backup.sh and rotate_logs.sh to the database server

Configure cron jobs for automated maintenance

Step 5: Verify Deployment
Once the script completes, access the search interface at:

text
http://34.228.58.26/lla/
Manual Deployment
If you prefer to deploy manually or need to troubleshoot individual components, follow these steps.

Part A: Database Server Setup
SSH into the database server:

bash
ssh -i your-key.pem ubuntu@[DB-SERVER-PRIVATE-IP]
Run the database setup script:

bash
# Copy the script to the server first (from your local machine)
scp -i your-key.pem setup_db.sh ubuntu@[DB-PRIVATE-IP]:~/

# SSH into the server
ssh -i your-key.pem ubuntu@[DB-PRIVATE-IP]

# Run the setup script
chmod +x setup_db.sh
sudo ./setup_db.sh
What the script does:

Updates system packages

Installs MySQL 8.0

Secures MySQL installation (removes anonymous users, disables remote root)

Creates lla_db database

Imports schema.sql (table structure)

Imports seed_data.sql (sample data)

Creates lla_user with restricted privileges

Configures firewall to allow MySQL only from web server IP

Configures MySQL to accept remote connections

Expected output:

text
=== DATABASE SERVER SETUP STARTING ===
=== DATABASE SERVER READY ===
Database 'lla_db' created with sample data
Part B: Web Server Setup
SSH into the web server:

bash
ssh -i your-key.pem ubuntu@[WEB-SERVER-PUBLIC-IP]
Run the web server setup script:

bash
# Copy the script to the server first
scp -i your-key.pem setup_web.sh ubuntu@[WEB-PUBLIC-IP]:~/

# SSH into the server
ssh -i your-key.pem ubuntu@[WEB-PUBLIC-IP]

# Run the setup script
chmod +x setup_web.sh
sudo ./setup_web.sh
What the script does:

Updates system packages

Installs Apache 2.4 and PHP 8.1

Creates the /var/www/html/lla/ directory

Deploys config.php with database connection settings

Deploys index.php with search interface

Configures firewall to allow HTTP (80) and HTTPS (443)

Hides Apache version information for security

Sets correct file permissions

Expected output:

text
=== WEB SERVER SETUP STARTING ===
=== WEB SERVER READY ===
Access your site at: http://34.228.58.26/lla/
Part C: Configure Automated Backups
On the database server, set up cron jobs for automated maintenance:

bash
# Copy backup scripts to the database server
scp -i your-key.pem backup.sh ubuntu@[DB-PRIVATE-IP]:~/
scp -i your-key.pem rotate_logs.sh ubuntu@[DB-PRIVATE-IP]:~/

# SSH into database server
ssh -i your-key.pem ubuntu@[DB-PRIVATE-IP]

# Make scripts executable
chmod +x backup.sh rotate_logs.sh

# Edit crontab
sudo crontab -e
Add the following lines to crontab:

bash
# Daily database backup at 2:00 AM
0 2 * * * /home/ubuntu/backup.sh

# Daily log rotation at 3:00 AM
0 3 * * * /home/ubuntu/rotate_logs.sh
Save and exit. Verify cron jobs are configured:

bash
sudo crontab -l
Verification Steps
After deployment, run these commands to verify the system is working correctly.

1. Verify Web Server is Running
bash
# Check Apache status
sudo systemctl status apache2

# Expected: active (running)

# Test web server response
curl -I http://localhost/lla/

# Expected: HTTP/1.1 200 OK
2. Verify Database Server is Running
bash
# Check MySQL status
sudo systemctl status mysql

# Expected: active (running)

# Test database connection
sudo mysql -e "USE lla_db; SELECT COUNT(*) FROM Book;"

# Expected: +----------+
#          | COUNT(*) |
#          +----------+
#          |       15 |
#          +----------+
3. Verify Web-to-Database Connection
bash
# From web server, test MySQL connectivity to database server
mysql -u lla_user -p'LibrarySecure2026!' -h 172.31.29.175 -e "SELECT 1"

# Expected output: +---+
#                  | 1 |
#                  +---+
#                  | 1 |
#                  +---+
4. Verify Search Interface
Open a web browser and navigate to:

text
http://34.228.58.26/lla/
Perform test searches:

"1984" – Should return George Orwell's 1984

"Harry" – Should return Harry Potter

"Austen" – Should return Pride and Prejudice

"xyz" – Should return "No results found"

5. Verify Backup Script
bash
# Run backup script manually
./backup.sh

# Check backup was created
ls -la /var/backups/lla_db/

# Expected output: backup_YYYYMMDD_HHMMSS.sql.gz

# Check backup log
cat /var/log/lla_backup.log
6. Verify Cron Jobs
bash
# List cron jobs
sudo crontab -l

# Expected output:
# 0 2 * * * /home/ubuntu/backup.sh
# 0 3 * * * /home/ubuntu/rotate_logs.sh
7. Verify Firewall Rules
On Web Server:

bash
sudo ufw status numbered
Expected:

text
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       [Your-IP]
80/tcp                     ALLOW       Anywhere
443/tcp                    ALLOW       Anywhere
On Database Server:

bash
sudo ufw status numbered
Expected:

text
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       [Your-IP]
3306/tcp                   ALLOW       34.228.58.26
8. Verify GDPR Compliance Features
bash
# Test GDPR anonymisation procedure
sudo mysql -e "USE lla_db; CALL GDPR_AnonymizeMember(1);"

# Verify member was anonymised
sudo mysql -e "USE lla_db; SELECT email, full_name, is_active FROM Member WHERE member_id=1;"

# Expected: deleted_1@anonymized.lla | [REDACTED] | 0
Maintenance
Daily Operations
Maintenance tasks are automated via cron jobs. No manual intervention is required for:

Task	Schedule	Script	Log Location
Database backup	Daily at 2:00 AM	backup.sh	/var/log/lla_backup.log
Log rotation	Daily at 3:00 AM	rotate_logs.sh	/var/log/lla_rotate.log
Manual Backup
To perform an immediate manual backup:

bash
# On database server
./backup.sh

# Verify backup was created
ls -la /var/backups/lla_db/
Restore from Backup
To restore the database from the most recent backup:

bash
# On database server
LATEST_BACKUP=$(ls -t /var/backups/lla_db/*.sql.gz | head -1)
gunzip -c $LATEST_BACKUP | sudo mysql lla_db
View Logs
bash
# View backup logs
cat /var/log/lla_backup.log

# View web server access logs
sudo tail -f /var/log/apache2/access.log

# View web server error logs
sudo tail -f /var/log/apache2/error.log

# View MySQL logs
sudo tail -f /var/log/mysql/error.log
Update Sample Data
To add new books to the database:

bash
# Connect to MySQL
sudo mysql -u root -p

# Insert new book
USE lla_db;
INSERT INTO Book (title, isbn, publication_year, total_copies, available_copies) 
VALUES ('New Book Title', '9781234567890', 2026, 3, 3);

# Insert author if new
INSERT INTO Author (name) VALUES ('New Author Name');

# Link book to author
INSERT INTO BookAuthor (book_id, author_id) VALUES (LAST_INSERT_ID(), [author_id]);

# Exit
EXIT;
Troubleshooting
Issue: Web Server Cannot Connect to Database
Symptom: Search interface shows "Connection failed" error.

Diagnosis:

bash
# From web server, test MySQL connectivity
nc -zv 172.31.29.175 3306
Solutions:

Verify database server is running: sudo systemctl status mysql

Verify MySQL bind address: sudo grep "bind-address" /etc/mysql/mysql.conf.d/mysqld.cnf

Verify firewall on database server: sudo ufw status

Verify security group allows MySQL from web server IP

Issue: Backup Script Fails
Symptom: No backups appear in /var/backups/lla_db/

Diagnosis:

bash
# Run script manually to see error
./backup.sh

# Check MySQL credentials in script
cat backup.sh | grep -i pass
Solutions:

Verify MySQL root password matches script

Create backup directory: sudo mkdir -p /var/backups/lla_db

Check disk space: df -h

Issue: Search Returns No Results
Symptom: Search interface works but returns zero results.

Diagnosis:

bash
# Check database has data
sudo mysql -e "USE lla_db; SELECT COUNT(*) FROM Book;"
Solutions:

Re-import seed data: sudo mysql lla_db < seed_data.sql

Verify web server can read database: Check error_log in Apache logs

Issue: SSH Connection Refused
Symptom: Cannot SSH into either server.

Solutions:

Verify security group allows SSH from your IP address

Check instance is running in AWS console

Verify you are using the correct key file

Check instance public IP address (may have changed after reboot)

Issue: Permission Denied on Scripts
Symptom: ./script.sh: Permission denied

Solution:

bash
chmod +x script.sh
File Reference
The following files are included in this deployment package:

Filename	Description	Destination Server
deploy.sh	Master deployment script	Local machine
setup_web.sh	Web server automation script	Web server
setup_db.sh	Database server automation script	Database server
backup.sh	Daily backup script	Database server
rotate_logs.sh	Log rotation script	Database server
schema.sql	Database schema (3NF)	Database server
seed_data.sql	Sample data	Database server
README.md	This file	Documentation
Database Schema Tables
Table	Purpose
Author	Stores author names
Publisher	Stores publisher details
Book	Stores book information
BookAuthor	Links books to authors (many-to-many)
Member	Stores library member data (GDPR compliant)
LoanHistory	Tracks book loans and returns
Reservation	Manages book reservations
AuditLog	Records data access for compliance
Security Considerations
The following security measures are implemented:

Layer	Measure
Network	Firewall with default-deny policy
Network	Database accessible only from web server IP
Host	SSH key authentication only
Host	Root login disabled
Application	Prepared statements prevent SQL injection
Application	Apache version hidden from HTTP headers
Data	Principle of least privilege for database user
Data	GDPR-compliant data minimisation
Data	Audit logging for all data access
Support
For issues or questions regarding this deployment:

Module: 5COM2006 Design and Configuration Project

Instructor: Dr Satrya Fajri Pratama

Team: [Team Name]

Version History
Version	Date	Changes	Author
1.0	[Date]	Initial release	[Team Name]
