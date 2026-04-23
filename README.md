# LLA Legacy Migration Project - Deployment Guide

**Project:** Local Library Archive (LLA) Digital Catalogue System | **Version:** 1.0 | **Last Updated:** 23 April 2026 | **Team:** [Your Team Name]

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Quick Deployment](#quick-deployment)
5. [Manual Deployment](#manual-deployment)
6. [Verification Steps](#verification-steps)
7. [Maintenance](#maintenance)
8. [Troubleshooting](#troubleshooting)
9. [File Reference](#file-reference)

---

## Overview

This deployment guide provides instructions for installing and configuring the LLA Legacy Migration digital catalogue system. The system consists of a web server hosting a PHP search interface and a database server storing library records. Both servers run on Ubuntu 22.04 LTS. Key features include a normalised SQL database in Third Normal Form (3NF), a web-based search interface for books by title or author, automated daily backups with 30-day retention, GDPR-compliant data handling with anonymisation procedures, and firewall-restricted database access implementing the principle of least privilege.

---

## Architecture

The system implements a three-tier architecture. The web server resides at 34.228.58.26 in a public subnet with open ports 22 (SSH), 80 (HTTP), and 443 (HTTPS). The database server resides at 172.31.29.175 in a private subnet with open ports 22 (SSH) and 3306 (MySQL), with MySQL access restricted exclusively to the web server IP address. Network flow follows this pattern: Internet traffic reaches the web server via ports 80 and 443, then the web server communicates with the database server via port 3306 through a firewall that blocks all direct internet access to the database.

---

## Prerequisites

Before beginning deployment, ensure you have the following AWS infrastructure: two Ubuntu 22.04 LTS t2.micro EC2 instances (one with a public IP for the web server, one with a private IP only for the database server). Security group for the web server must allow SSH (22) from your admin IP, HTTP (80) from 0.0.0.0/0, and HTTPS (443) from 0.0.0.0/0. Security group for the database server must allow SSH (22) from your admin IP and MySQL (3306) from the web server IP address only. You will also need a .pem key pair file for SSH access to both instances. On your local machine, you need an SSH client, Git installed, and access to the project repository.

---

## Quick Deployment

The system can be deployed automatically using the provided `deploy.sh` script. First, clone the repository using `git clone [your-repository-url]` and navigate into the directory. Open `deploy.sh` and update the following variables: `WEB_IP="34.228.58.26"`, `DB_IP="172.31.29.175"`, and `KEY_PATH="/path/to/your-key.pem"`. Make all scripts executable by running `chmod +x deploy.sh setup_web.sh setup_db.sh backup.sh rotate_logs.sh`. Then run `./deploy.sh` to execute the automated deployment. Once completed, access the search interface at `http://34.228.58.26/lla/`.

---

## Manual Deployment

If you prefer to deploy manually, follow these steps. For the database server, SSH into the server using `ssh -i your-key.pem ubuntu@172.31.29.175`. Run `chmod +x setup_db.sh` followed by `sudo ./setup_db.sh`. The script will update system packages, install MySQL 8.0, secure the installation by removing anonymous users and disabling remote root login, create the `lla_db` database, import `schema.sql` and `seed_data.sql`, create the restricted `lla_user` with least privileges, configure the firewall to allow MySQL only from the web server IP, and configure MySQL to accept remote connections. Expected output is "DATABASE SERVER READY" with confirmation that the database was created with sample data.

For the web server, SSH into the server using `ssh -i your-key.pem ubuntu@34.228.58.26`. Run `chmod +x setup_web.sh` followed by `sudo ./setup_web.sh`. The script will update system packages, install Apache 2.4 and PHP 8.1, create the `/var/www/html/lla/` directory, deploy `config.php` with database connection settings, deploy `index.php` with the search interface, configure the firewall to allow HTTP and HTTPS, hide Apache version information for security, and set correct file permissions. Expected output is "WEB SERVER READY" with the URL to access the site.

For automated backups, on the database server make the backup scripts executable with `chmod +x backup.sh rotate_logs.sh`. Edit the crontab using `sudo crontab -e` and add the following lines: `0 2 * * * /home/ubuntu/backup.sh` for daily database backup at 2 AM, and `0 3 * * * /home/ubuntu/rotate_logs.sh` for daily log rotation at 3 AM. Verify cron jobs are configured by running `sudo crontab -l`.

---

## Verification Steps

After deployment, run these commands to verify the system is working correctly. Verify the web server is running with `sudo systemctl status apache2` which should show "active (running)", and test the web server response with `curl -I http://localhost/lla/` which should return HTTP/1.1 200 OK. Verify the database server is running with `sudo systemctl status mysql` which should show "active (running)", and test the database has data with `sudo mysql -e "USE lla_db; SELECT COUNT(*) FROM Book;"` which should return 15. Verify the web-to-database connection from the web server using `mysql -u lla_user -p'LibrarySecure2026!' -h 172.31.29.175 -e "SELECT 1"` which should return a table with the value 1.

Verify the search interface by opening a web browser and navigating to `http://34.228.58.26/lla/`. Perform test searches: "1984" should return George Orwell's 1984, "Harry" should return Harry Potter and the Philosopher's Stone, "Austen" should return Pride and Prejudice, and "xyz" should return "No results found". Verify the backup script by running `./backup.sh` manually, then checking `ls -la /var/backups/lla_db/` which should show a file named `backup_YYYYMMDD_HHMMSS.sql.gz`, and checking the log with `cat /var/log/lla_backup.log`. Verify cron jobs with `sudo crontab -l` which should show the two cron entries. Verify firewall rules on the web server with `sudo ufw status numbered` which should show SSH allowed from your IP, and HTTP and HTTPS allowed from anywhere. On the database server, `sudo ufw status numbered` should show SSH allowed from your IP and MySQL allowed from 34.228.58.26 only.

Verify GDPR compliance features by testing the anonymisation procedure with `sudo mysql -e "USE lla_db; CALL GDPR_AnonymizeMember(1);"` followed by `sudo mysql -e "USE lla_db; SELECT email, full_name, is_active FROM Member WHERE member_id=1;"` which should return a deleted email address, "[REDACTED]" as the name, and 0 for active status.

---

## Maintenance

Daily operations are automated via cron jobs. The database backup runs daily at 2:00 AM using `backup.sh` with logs written to `/var/log/lla_backup.log`. Log rotation runs daily at 3:00 AM using `rotate_logs.sh` with logs written to `/var/log/lla_rotate.log`. No manual intervention is required for routine maintenance.

To perform an immediate manual backup, run `./backup.sh` on the database server, then verify the backup was created with `ls -la /var/backups/lla_db/`. To restore from the most recent backup, run `LATEST_BACKUP=$(ls -t /var/backups/lla_db/*.sql.gz | head -1)` followed by `gunzip -c $LATEST_BACKUP | sudo mysql lla_db`. To view logs, use `cat /var/log/lla_backup.log` for backup logs, `sudo tail -f /var/log/apache2/access.log` for web server access logs, `sudo tail -f /var/log/apache2/error.log` for web server error logs, or `sudo tail -f /var/log/mysql/error.log` for MySQL logs.

To add new books to the database, connect to MySQL with `sudo mysql -u root -p`, then use the `lla_db` database with `USE lla_db;`. Insert a new book using `INSERT INTO Book (title, isbn, publication_year, total_copies, available_copies) VALUES ('New Book Title', '9781234567890', 2026, 3, 3);`. Insert a new author if needed using `INSERT INTO Author (name) VALUES ('New Author Name');`. Link the book to the author using `INSERT INTO BookAuthor (book_id, author_id) VALUES (LAST_INSERT_ID(), [author_id]);`. Exit MySQL with `EXIT;`.

---

## Troubleshooting

If the web server cannot connect to the database, the search interface will show a "Connection failed" error. Diagnose by running `nc -zv 172.31.29.175 3306` from the web server. Solutions include verifying the database server is running with `sudo systemctl status mysql`, verifying the MySQL bind address is not set to 127.0.0.1 only by checking `sudo grep "bind-address" /etc/mysql/mysql.conf.d/mysqld.cnf`, verifying the firewall on the database server with `sudo ufw status`, and verifying the AWS security group allows MySQL traffic from the web server IP address.

If the backup script fails, no backups will appear in `/var/backups/lla_db/`. Diagnose by running `./backup.sh` manually to see the error message. Solutions include verifying the MySQL root password in the script matches the actual root password, creating the backup directory manually with `sudo mkdir -p /var/backups/lla_db`, and checking available disk space with `df -h`.

If the search interface returns no results, the search works but returns zero results for queries that should match. Diagnose by checking if the database has data with `sudo mysql -e "USE lla_db; SELECT COUNT(*) FROM Book;"`. Solutions include re-importing the seed data with `sudo mysql lla_db < seed_data.sql` and checking the Apache error logs with `sudo tail -f /var/log/apache2/error.log`.

If SSH connection is refused, you cannot access either server. Solutions include verifying the security group allows SSH from your current IP address (note that your IP may have changed), checking that the instance is running in the AWS console, verifying you are using the correct .pem key file, and checking that the instance public IP address has not changed after a reboot.

If you receive a "Permission denied" error when trying to run scripts, the scripts are not executable. Fix by running `chmod +x script_name.sh` for each script.

---

## File Reference

The following files are included in this deployment package. `deploy.sh` is the master deployment script that runs on your local machine. `setup_web.sh` is the web server automation script that runs on the web server. `setup_db.sh` is the database server automation script that runs on the database server. `backup.sh` is the daily backup script that runs on the database server. `rotate_logs.sh` is the log rotation script that runs on the database server. `schema.sql` contains the database schema in Third Normal Form (3NF) and runs on the database server. `seed_data.sql` contains sample data for testing and runs on the database server. `README.md` is this documentation file.

The database schema includes eight tables. `Author` stores author names with a unique constraint. `Publisher` stores publisher details separately to eliminate transitive dependency. `Book` stores core bibliographic information with foreign keys to Publisher. `BookAuthor` is a junction table linking books to authors in a many-to-many relationship. `Member` stores library member data with GDPR-compliant data minimisation. `LoanHistory` tracks all book loans and returns with referential integrity. `Reservation` manages book reservations for borrowed books. `AuditLog` records all data access for compliance auditing.

---

## Security Considerations

The following security measures are implemented at each layer. At the network layer, a firewall with default-deny policy blocks all traffic except explicitly allowed ports, and the database is accessible only from the web server IP address. At the host layer, SSH key authentication is required with password authentication disabled and root login prohibited. At the application layer, prepared statements prevent SQL injection attacks, and Apache version information is hidden from HTTP headers. At the data layer, the principle of least privilege restricts the database user to only SELECT, INSERT, and UPDATE privileges, GDPR-compliant data minimisation ensures no unnecessary personal data is collected, and audit logging records all data access for compliance reporting.

---

## Version History

Version 1.0 released on 23 April 2026 as initial release.

