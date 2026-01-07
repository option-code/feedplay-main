@echo off
setlocal enabledelayedexpansion
title Flutter Web + Python Server (Dynamic Port)

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

REM Step 3: Get a free dynamic port using Python
for /f %%p in ('python -c "import socket;s=socket.socket();s.bind(('',0));print(s.getsockname()[1]);s.close()"') do (
    set PORT=%%p
)

echo [3/4] Assigned free port: %PORT%
echo.

REM Step 4: Start Python server
echo Starting Python server...
echo Server will run until you press Ctrl+C to stop it.
echo Opening browser... please wait.

cd /d "%~dp0build\web"

REM Open browser on dynamic port
start http://localhost:%PORT%

echo.
echo ========================================
echo Server started at http://localhost:%PORT%
echo Press Ctrl+C to stop the server
echo ========================================
echo.

python -m http.server %PORT%

REM Step 5: Go back to project root when server stops
cd /d "%~dp0"

echo.
echo Server stopped.
pause
endlocal
