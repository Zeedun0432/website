#!/bin/bash

# Zeedun Gaming Cloud Service - VPS Deployment Script
# Ubuntu 20.04/22.04 LTS

echo "🚀 Starting Zeedun Gaming Cloud Service deployment..."

# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y nginx mysql-server php8.1 php8.1-fpm php8.1-mysql php8.1-curl php8.1-json php8.1-mbstring php8.1-xml php8.1-zip php8.1-gd php8.1-bcmath unzip curl git

# Install Node.js and npm for frontend build
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Configure MySQL
sudo mysql_secure_installation

echo "📁 Setting up project directories..."

# Create project directory
sudo mkdir -p /var/www/zeedun
sudo chown -R $USER:$USER /var/www/zeedun

# Clone or upload your project files here
cd /var/www/zeedun

# Build React frontend
echo "🔨 Building React frontend..."
npm install
npm run build

# Move built files to public directory
sudo mkdir -p /var/www/zeedun/public
sudo cp -r dist/* /var/www/zeedun/public/

# Set proper permissions
sudo chown -R www-data:www-data /var/www/zeedun
sudo chmod -R 755 /var/www/zeedun

# Configure Nginx
sudo tee /etc/nginx/sites-available/zeedun << EOF
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    root /var/www/zeedun/public;
    index index.php index.html index.htm;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # API routes (if you add PHP backend)
    location /api {
        try_files \$uri \$uri/ /api/index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }

    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2|ttf|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Enable site
sudo ln -s /etc/nginx/sites-available/zeedun /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Restart services
sudo systemctl restart nginx
sudo systemctl restart php8.1-fpm

# Enable services to start on boot
sudo systemctl enable nginx
sudo systemctl enable php8.1-fpm
sudo systemctl enable mysql

echo "🔒 Setting up SSL with Let's Encrypt..."
sudo apt install -y certbot python3-certbot-nginx

# Note: Replace 'your-domain.com' with your actual domain
# sudo certbot --nginx -d your-domain.com -d www.your-domain.com

echo "🗄️ Setting up database..."
# Import database schema
mysql -u root -p < database/schema.sql

echo "🔧 Setting up firewall..."
sudo ufw allow 'Nginx Full'
sudo ufw allow ssh
sudo ufw --force enable

echo "✅ Deployment completed!"
echo ""
echo "📋 Next steps:"
echo "1. Update your domain DNS to point to this server"
echo "2. Run: sudo certbot --nginx -d your-domain.com -d www.your-domain.com"
echo "3. Configure your database credentials"
echo "4. Set up Tripay API credentials"
echo "5. Configure Pterodactyl API (if using)"
echo ""
echo "🌐 Your site should be accessible at: http://your-server-ip"
