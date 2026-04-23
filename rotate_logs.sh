#!/bin/bash
# rotate_logs.sh - Log rotation script

LOG_DIR="/var/log"
DAYS_TO_KEEP=30

# Delete old logs
find $LOG_DIR -name "*.log" -mtime +$DAYS_TO_KEEP -delete 2>/dev/null

# Compress logs older than 7 days
find $LOG_DIR -name "*.log" -mtime +7 -exec gzip {} \; 2>/dev/null

echo "$(date): Log rotation completed" >> /var/log/rotation.log