#!/bin/bash

# Script to bump Android version in pubspec.yaml
# Usage: ./bump_version.sh [major|minor|patch]

set -e

BUMP_TYPE=${1:-patch}
PUBSPEC_FILE="pubspec.yaml"

# Get current version
CURRENT_VERSION=$(grep "^version:" $PUBSPEC_FILE | sed 's/version: //')
VERSION_NAME=$(echo $CURRENT_VERSION | cut -d'+' -f1)
BUILD_NUMBER=$(echo $CURRENT_VERSION | cut -d'+' -f2)

# Split version name into components
MAJOR=$(echo $VERSION_NAME | cut -d'.' -f1)
MINOR=$(echo $VERSION_NAME | cut -d'.' -f2)
PATCH=$(echo $VERSION_NAME | cut -d'.' -f3)

# Increment based on type
case $BUMP_TYPE in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
  *)
    echo "Invalid bump type: $BUMP_TYPE"
    echo "Usage: $0 [major|minor|patch]"
    exit 1
    ;;
esac

# Increment build number
BUILD_NUMBER=$((BUILD_NUMBER + 1))

# Create new version string
NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}+${BUILD_NUMBER}"

echo "Bumping version from $CURRENT_VERSION to $NEW_VERSION"

# Update pubspec.yaml (compatible with both macOS and Linux)
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS (BSD sed)
  sed -i '' "s/^version: .*/version: $NEW_VERSION/" $PUBSPEC_FILE
else
  # Linux (GNU sed)
  sed -i "s/^version: .*/version: $NEW_VERSION/" $PUBSPEC_FILE
fi

echo "Version updated successfully!"
echo "New version: $NEW_VERSION"
