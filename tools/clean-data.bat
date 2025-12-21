@echo off
echo ========================================
echo   Clean data.json - Remove Fields
echo ========================================
echo.

cd /d "%~dp0\.."

echo Checking Node.js installation...
node --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js is not installed or not in PATH
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

echo Node.js found!
echo.

echo Running cleanup script...
node tools\clean-data.json.js

echo.
echo ========================================
echo   Cleanup Complete!
echo ========================================
pause

