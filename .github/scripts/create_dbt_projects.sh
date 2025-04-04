#!/bin/bash
set -e

echo "Creating dbt projects..."

PROJECT_DIR="$HOME/project"
DBT_PROFILES_DIR="$HOME/.dbt"

echo -e "Project dir: $PROJECT_DIR\n"
echo -e "dbt profiles dir: $DBT_PROFILES_DIR\n"

# Ensure the workspace directories exist
mkdir -p "$PROJECT_DIR"
mkdir -p "$DBT_PROFILES_DIR"

# Extract the ZIP file
echo "Extracting project ZIP..."
unzip -o .github/scripts/projects.zip -d "$PROJECT_DIR"

# Move profiles.yml to the correct directory
echo "Setting up profiles.yml..."
cp .github/scripts/profiles.yml "$DBT_PROFILES_DIR/profiles.yml"

echo "DBT project setup is complete."
