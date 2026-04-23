#!/bin/bash
# =============================================================
# Local Library Archive (LLA) -- Legacy Migration Project
# Script: setup_db.sh
# Purpose: Automated setup of the MySQL database server on
#          AWS EC2 (Ubuntu 22.04 LTS).
#          - Installs and secures MySQL
#          - Creates the lla_db database
#          - Runs the schema and seed data
#          - Creates restricted lla_user for the web server
#          - Hardens MySQL configuration
# Usage: sudo bash setup_db.sh
# Team: Data Dwellers -- 5COM2006
# =============================================================

set -e          # Exit immediately if any command fails
set -u          # Treat unset variables as errors
set -o pipefail # Catch errors inside pipes

# =============================================================
# CONFIGURATION -- edit these before running
# =============================================================
DB_NAME="lla_db"
DB_ROOT_PASS="12345678"      # MySQL root password
DB_APP_USER="lla_user"
DB_APP_PASS="87654321"        # Web app DB password
WEB_SERVER_IP="172.31.15.233"     # Private IP of web EC2

SCHEMA_FILE="/home/ubuntu/schema.sql"
SEED_FILE="/home/ubuntu/seed_data.sql"

LOG_FILE="/var/log/lla_setup_db.log"

# =============================================================
# LOGGING HELPER
# All output goes to both screen and log file
# =============================================================
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# =============================================================
# STEP 1 -- System update
# =============================================================
log "INFO: Updating system packages..."
apt-get update -y >> "$LOG_FILE" 2>&1
apt-get upgrade -y >> "$LOG_FILE" 2>&1
log "INFO: System update complete."

# =============================================================
# STEP 2 -- Install MySQL Server (idempotent)
# =============================================================
if dpkg -l | grep -q mysql-server; then
    log "INFO: MySQL already installed. Skipping."
else
    log "INFO: Installing MySQL Server..."
    apt-get install -y mysql-server >> "$LOG_FILE" 2>&1
    log "INFO: MySQL installation complete."
fi

# Start and enable MySQL
systemctl start mysql
systemctl enable mysql
log "INFO: MySQL service started and enabled."

# =============================================================
# STEP 3 -- Set MySQL root password and secure installation
# Automates the equivalent of mysql_secure_installation
# =============================================================
log "INFO: Securing MySQL installation..."

mysql -u root << EOF
-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_ROOT_PASS}';

-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';

-- Remove remote root login (security hardening)
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Remove test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Apply changes
FLUSH PRIVILEGES;
EOF

log "INFO: MySQL secured."

# =============================================================
# STEP 4 -- Create the application database
# =============================================================
log "INFO: Creating database ${DB_NAME}..."

mysql -u root -p"${DB_ROOT_PASS}" << EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME}
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
EOF

log "INFO: Database ${DB_NAME} created."

# =============================================================
# STEP 5 -- Run schema and seed data
# =============================================================
if [ -f "${SCHEMA_FILE}" ]; then
    log "INFO: Running schema.sql..."
    mysql -u root -p"${DB_ROOT_PASS}" "${DB_NAME}" < "${SCHEMA_FILE}" >> "$LOG_FILE" 2>&1
    log "INFO: Schema applied successfully."
else
    log "ERROR: Schema file not found at ${SCHEMA_FILE}. Aborting."
    exit 1
fi

if [ -f "${SEED_FILE}" ]; then
    log "INFO: Running seed_data.sql..."
    mysql -u root -p"${DB_ROOT_PASS}" "${DB_NAME}" < "${SEED_FILE}" >> "$LOG_FILE" 2>&1
    log "INFO: Seed data loaded successfully."
else
    log "WARNING: Seed file not found at ${SEED_FILE}. Skipping seed data."
fi

# =============================================================
# STEP 6 -- Create restricted application user
# Principle of Least Privilege: lla_user can only SELECT,
# INSERT, UPDATE on lla_db. No DELETE, no access to other DBs,
# no admin privileges. Only accessible from the web server IP.
# =============================================================
log "INFO: Creating application user ${DB_APP_USER}..."

mysql -u root -p"${DB_ROOT_PASS}" << EOF
-- Drop user if exists (idempotent)
DROP USER IF EXISTS '${DB_APP_USER}'@'${WEB_SERVER_IP}';

-- Create with restricted host (web server private IP only)
CREATE USER '${DB_APP_USER}'@'${WEB_SERVER_IP}'
    IDENTIFIED BY '${DB_APP_PASS}';

-- Grant minimum necessary permissions only
GRANT SELECT, INSERT, UPDATE ON ${DB_NAME}.Book        TO '${DB_APP_USER}'@'${WEB_SERVER_IP}';
GRANT SELECT, INSERT, UPDATE ON ${DB_NAME}.Author      TO '${DB_APP_USER}'@'${WEB_SERVER_IP}';
GRANT SELECT, INSERT, UPDATE ON ${DB_NAME}.BookAuthor  TO '${DB_APP_USER}'@'${WEB_SERVER_IP}';
GRANT SELECT, INSERT, UPDATE ON ${DB_NAME}.Member      TO '${DB_APP_USER}'@'${WEB_SERVER_IP}';
GRANT SELECT, INSERT, UPDATE ON ${DB_NAME}.LoanHistory TO '${DB_APP_USER}'@'${WEB_SERVER_IP}';

-- No DELETE granted -- soft deletion used instead (GDPR audit trail)

FLUSH PRIVILEGES;
EOF

log "INFO: Application user ${DB_APP_USER} created with least-privilege permissions."

# =============================================================
# STEP 7 -- Harden MySQL configuration
# Binds MySQL to private IP only (not 0.0.0.0)
# Disables local file loading (prevents data exfiltration)
# =============================================================
log "INFO: Hardening MySQL configuration..."

MYSQL_CONF="/etc/mysql/mysql.conf.d/mysqld.cnf"

# Backup original config (idempotent -- only backup once)
if [ ! -f "${MYSQL_CONF}.original" ]; then
    cp "${MYSQL_CONF}" "${MYSQL_CONF}.original"
    log "INFO: Original MySQL config backed up."
fi

# Bind to private IP only -- prevents public internet access to port 3306
# Replace the default 127.0.0.1 bind with the DB server's own private IP
PRIVATE_IP=$(hostname -I | awk '{print $1}')
sed -i "s/^bind-address\s*=.*/bind-address = ${PRIVATE_IP}/" "${MYSQL_CONF}"

# If bind-address line doesn't exist, add it
grep -q "^bind-address" "${MYSQL_CONF}" || \
    echo "bind-address = ${PRIVATE_IP}" >> "${MYSQL_CONF}"

# Disable LOAD DATA LOCAL INFILE (security hardening)
grep -q "^local-infile" "${MYSQL_CONF}" || \
    echo "local-infile = 0" >> "${MYSQL_CONF}"

log "INFO: MySQL bound to private IP: ${PRIVATE_IP}"

# =============================================================
# STEP 8 -- Restart MySQL to apply config changes
# =============================================================
systemctl restart mysql
log "INFO: MySQL restarted with hardened configuration."

# =============================================================
# STEP 9 -- Verify MySQL is running
# =============================================================
if systemctl is-active --quiet mysql; then
    log "SUCCESS: MySQL is running correctly."
else
    log "ERROR: MySQL failed to start. Check ${LOG_FILE} for details."
    exit 1
fi

# =============================================================
# STEP 10 -- Configure AWS Security Group reminder
# =============================================================
log ""
log "======================================================"
log "IMPORTANT: AWS Security Group Configuration Required"
log "======================================================"
log "On your DB EC2 Security Group, ensure:"
log "  - Inbound port 3306 (MySQL) allowed ONLY from web server private IP: ${WEB_SERVER_IP}"
log "  - Inbound port 22 (SSH) allowed ONLY from your own IP"
log "  - NO inbound rules open to 0.0.0.0/0 on port 3306"
log "======================================================"
log ""
log "Database setup complete. Log saved to ${LOG_FILE}"
