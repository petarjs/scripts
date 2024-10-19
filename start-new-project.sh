#!/bin/bash

# Function to create a new local database using PHP
create_database() {
  local db_name=$1

  echo "Attempting to create database ${db_name} using PHP..."

  php -r "
    try {
      \$pdo = new PDO('mysql:host=127.0.0.1', 'root', '');
      \$pdo->exec(\"CREATE DATABASE IF NOT EXISTS \`$db_name\`\");
      echo \"Database $db_name created successfully.\n\";
    } catch (PDOException \$e) {
      echo \"Error creating database: \" . \$e->getMessage() . \"\n\";
      exit(1);
    }
  "
}

# Function to generate a random color
generate_random_color() {
  printf "%02x%02x%02x" $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256))
}

# Function to update VS Code settings with a new color
update_vscode_settings() {
  local project_dir=$1
  local color=$2
  
  local settings_file="$project_dir/.vscode/settings.json"
  
  # Ensure .vscode directory exists
  mkdir -p "$project_dir/.vscode"
  
  # If settings.json doesn't exist, create it with a basic structure
  if [ ! -f "$settings_file" ]; then
    echo '{
  "cSpell.words": ["superadmin"],
  "workbench.colorCustomizations": {}
}' > "$settings_file"
  fi
  
  # Update the color settings using sed
  sed -i '' -e "s/\"workbench.colorCustomizations\": {[^}]*}/\"workbench.colorCustomizations\": {\n    \"statusBar.background\": \"#$color\",\n    \"statusBar.foreground\": \"#ffffff\",\n    \"titleBar.activeBackground\": \"#$color\",\n    \"titleBar.activeForeground\": \"#ffffff\",\n    \"titleBar.inactiveBackground\": \"#$color\",\n    \"titleBar.inactiveForeground\": \"#e7e7e799\"\n  }/g" "$settings_file"
}

# Prompt for app name and port number
read -p "Enter the app name: " APP_NAME
read -p "Enter the port number: " NEW_PORT
read -p "Enter the redis database number: " REDIS_DB

cd /Users/petarq/projects/personal/saasdev

ss p

# ---------------------------------------------------------------------------- #
#                                   FRONTEND                                   #
# ---------------------------------------------------------------------------- #

echo "Creating a new project $APP_NAME on port $NEW_PORT"

# Clone the repo in a new folder
git clone git@github.com:petarjs/www.saasdev.git $APP_NAME

# Navigate to the new app folder
cd $APP_NAME

echo "Installing dependencies..."

# Install the dependencies
bun i

echo "Creating a new branch..."

# Create a new app branch
git checkout -b app/$APP_NAME

echo "Updating the port in package.json..."

# Update the port in package.json
sed -i '' "s/-p 3000/-p $NEW_PORT/g" "package.json"

echo "Setting up proxy..."

# Set up valet proxy domain
valet proxy $APP_NAME http://localhost:$NEW_PORT --secure

echo "Setting up .env..."

# Set up .env.local
cp .env.example .env.local

# Replace placeholders in .env
sed -i '' "s|https://api.saasdev.test|https://api.$APP_NAME.test|g" ".env.local"
sed -i '' "s|https://saasdev.test|https://$APP_NAME.test|g" ".env.local"

# Generate a random color for the project
PROJECT_COLOR=$(generate_random_color)

# Update VS Code settings for frontend
update_vscode_settings . $PROJECT_COLOR

# Open the app in Cursor
cursor .

# ---------------------------------------------------------------------------- #
#                                    BACKEND                                   #
# ---------------------------------------------------------------------------- #

DB_NAME=$APP_NAME

echo "Creating a new database $DB_NAME"

# Create new local database
create_database $DB_NAME

# Navigate to Valet directory
cd ~/valet

echo "Creating a new api project $APP_NAME"

# Clone the repo in a new folder
git clone git@github.com:petarjs/api.saasdev.git api.$APP_NAME

# Navigate to the new app folder
cd api.$APP_NAME

# Create a new app branch
git checkout -b app/$APP_NAME

# Set up Valet SSL
sudo valet secure api.$APP_NAME

# Set up .env.local
cp .env.example .env

# Update .env with the database name and other variables
sed -i '' "s|DB_DATABASE=.*|DB_DATABASE=$DB_NAME|" .env
sed -i '' "s|APP_NAME=.*|APP_NAME=$APP_NAME|" .env
sed -i '' "s|APP_URL=.*|APP_URL=https://api.$APP_NAME.test|" .env
sed -i '' "s|FRONTEND_URL=.*|FRONTEND_URL=https://$APP_NAME.test|" .env
sed -i '' "s|CORS_ALLOWED_ORIGIN=.*|CORS_ALLOWED_ORIGIN=https://$APP_NAME.test|" .env
sed -i '' "s|SANCTUM_STATEFUL_DOMAINS=.*|SANCTUM_STATEFUL_DOMAINS=https://$APP_NAME.test|" .env
sed -i '' "s|SESSION_DOMAIN=.*|SESSION_DOMAIN=.$APP_NAME.test|" .env
sed -i '' "s|REDIS_CACHE_DB=.*|REDIS_CACHE_DB=$REDIS_DB|" .env
sed -i '' "s|REDIS_DB=.*|REDIS_DB=$REDIS_DB|" .env

# Install dependencies
composer install

# Set up Laravel stuff
php artisan key:generate
php artisan migrate:fresh --seed
php artisan storage:link

# Set up IP Info stuff
mkdir -p storage/app/ipinfo
php artisan ipinfo:update

# Update VS Code settings for backend
update_vscode_settings . $PROJECT_COLOR

echo "Opening the project in Cursor..."
cursor .

# Open FE and BE in browser
open https://api.$APP_NAME.test/auth/login
open https://$APP_NAME.test
