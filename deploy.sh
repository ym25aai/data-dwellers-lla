#!/bin/bash
# Master deployment script - Run this from your local machine

echo "=== DEPLOYING LIBRARY SYSTEM ==="

# Variables
WEB_IP="34.228.58.26"
DB_IP="172.31.29.175"
KEY_PATH="~/.ssh/your-key.pem"  # Update with your AWS key path

# Deploy to Database Server
echo "1. Setting up Database Server..."
scp -i $KEY_PATH setup_db.sh ubuntu@$DB_IP:~/
ssh -i $KEY_PATH ubuntu@$DB_IP "chmod +x ~/setup_db.sh && ~/setup_db.sh"

# Deploy to Web Server
echo "2. Setting up Web Server..."
scp -i $KEY_PATH setup_web.sh ubuntu@$WEB_IP:~/
ssh -i $KEY_PATH ubuntu@$WEB_IP "chmod +x ~/setup_web.sh && ~/setup_web.sh"

# Deploy backup scripts
echo "3. Deploying backup scripts..."
scp -i $KEY_PATH backup.sh ubuntu@$DB_IP:~/
scp -i $KEY_PATH rotate_logs.sh ubuntu@$DB_IP:~/
ssh -i $KEY_PATH ubuntu@$DB_IP "chmod +x ~/backup.sh ~/rotate_logs.sh"

# Setup cron jobs
echo "4. Setting up cron jobs..."
ssh -i $KEY_PATH ubuntu@$DB_IP << 'EOF'
(crontab -l 2>/dev/null; echo "0 2 * * * /home/ubuntu/backup.sh") | crontab -
(crontab -l 2>/dev/null; echo "0 3 * * * /home/ubuntu/rotate_logs.sh") | crontab -
EOF

echo "=== DEPLOYMENT COMPLETE ==="
echo "Website: http://$WEB_IP/lla/"