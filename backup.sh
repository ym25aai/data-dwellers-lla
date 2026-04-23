#!/bin/bash
# backup.sh - Daily backup script

BACKUP_DIR="/var/backups/lla_db"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="lla_db"
DB_PASS="RootPass2026!"

# Create backup directory
mkdir -p $BACKUP_DIR

# Perform backup
mysqldump -u root -p${DB_PASS} ${DB_NAME} > ${BACKUP_DIR}/backup_${DATE}.sql

# Compress
gzip ${BACKUP_DIR}/backup_${DATE}.sql

# Delete backups older than 30 days
find $BACKUP_DIR -name "*.sql.gz" -mtime +30 -delete

echo "$(date): Backup completed - backup_${DATE}.sql.gz" >> /var/log/backup.log