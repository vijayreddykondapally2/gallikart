#!/bin/bash

# Auto-upload script for GalliKart
# Runs every hour to commit and push changes

cd /Users/apple/Desktop/Gallikart

# Check if there are changes
if [ -n "$(git status --porcelain)" ]; then
    echo "Changes detected. Uploading..."
    git add .
    git commit -m "Auto-upload: $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin master
    echo "Upload complete at $(date)"
else
    echo "No changes at $(date)"
fi