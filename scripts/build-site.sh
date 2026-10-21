#!/bin/sh
# Compose the site: the landing at /, the live web game at /app (the landing embeds it at app/?embed).
set -e
cd "$(dirname "$0")/.."
rm -rf dist && mkdir -p dist/app
cp -R landing/. dist/
for f in index.html style.css js icon.svg favicon.svg favicon-32.png apple-touch-icon.png privacy.html; do
  cp -R "web/$f" "dist/app/$f"
done
echo "built dist/ (landing at /, game at /app)"
