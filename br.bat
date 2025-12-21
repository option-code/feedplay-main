@echo off
setlocal enabledelayedexpansion
title Flutter Web + Python Server

echo ========================================
echo Build Flutter Web and Run Python Server
echo ========================================
echo.

REM Step 1: Build the Flutter web project
echo [1/4] Building Flutter web...
call flutter build web --release --pwa-strategy=none
if errorlevel 1 (
    echo.
    echo ERROR: Flutter build failed!
    pause
    exit /b 1
)

echo.
echo [2/4] Build successful!
echo.

REM Step 2: Check if build/web exists
if not exist "build\web" (
    echo ERROR: build\web folder not found!
    pause
    exit /b 1
)

REM Step 3: Start Python server in foreground so it can be killed properly
echo [3/4] Starting Python server on port 9090...
echo Server will run until you press Ctrl+C to stop it.
echo Opening browser... please wait.
cd /d "%~dp0build\web"

REM Open browser in a separate process
start http://localhost:9090

REM Run Python server in foreground so it can be properly terminated
echo.
echo ========================================
echo Server started at http://localhost:9090
echo Press Ctrl+C to stop the server
echo ========================================
echo.

python -m http.server 9090

REM Step 4: Go back to project root when server is stopped
cd /d "%~dp0"

echo.
echo Server stopped.
echo.
pause
endlocal