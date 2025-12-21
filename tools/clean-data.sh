#!/bin/bash

echo "========================================"
echo "  Clean data.json - Remove Fields"
echo "========================================"
echo ""

# Change to project root directory
cd "$(dirname "$0")/.."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "ERROR: Node.js is not installed or not in PATH"
    echo "Please install Node.js from https://nodejs.org/"
    exit 1
fi

echo "Node.js found!"
echo ""

# Run the cleanup script
node tools/clean-data.json.js

echo ""
echo "========================================"
echo "  Cleanup Complete!"
echo "========================================"

