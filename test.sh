#!/bin/bash

# 设置中文编码
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================"
echo "Express Delivery System - Test"
echo -e "========================================${NC}"
echo
echo "Current Directory: $(pwd)"
echo "Current Time: $(date)"
echo
echo "Testing basic functionality..."
echo

echo "[1/3] Checking Node.js..."
if command -v node &> /dev/null; then
    echo -e "${GREEN}SUCCESS: Node.js is installed${NC}"
else
    echo -e "${RED}ERROR: Node.js not found${NC}"
fi

echo
echo "[2/3] Checking project files..."
if [ -d "backend" ]; then
    echo -e "${GREEN}SUCCESS: backend directory exists${NC}"
else
    echo -e "${RED}ERROR: backend directory not found${NC}"
fi

if [ -f "backend/package.json" ]; then
    echo -e "${GREEN}SUCCESS: package.json exists${NC}"
else
    echo -e "${RED}ERROR: package.json not found${NC}"
fi

echo
echo "[3/3] Checking MySQL..."
if command -v mysql &> /dev/null; then
    echo -e "${GREEN}SUCCESS: MySQL is installed${NC}"
else
    echo -e "${RED}ERROR: MySQL not found${NC}"
fi

echo
echo -e "${BLUE}========================================"
echo "Test completed!"
echo -e "========================================${NC}"
echo
read -p "Press Enter to exit..." 