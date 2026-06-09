#!/bin/bash
set -e

echo "=== Cloning Flutter Stable SDK ==="
git clone https://github.com/flutter/flutter.git -b stable --depth 1

echo "=== Adding Flutter to PATH ==="
export PATH="$PATH:$(pwd)/flutter/bin"

echo "=== Verifying Flutter and Pre-downloading Web Binaries ==="
flutter precache --web
flutter doctor

echo "=== Building Flutter Web App (Release Mode) ==="
flutter build web --release

echo "=== Preparing Deployment Directory ==="
mkdir -p public
cp -r build/web/* public/

echo "=== Build Completed Successfully ==="
