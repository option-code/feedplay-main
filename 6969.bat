@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Run Python Server with Dynamic Port
echo ========================================
echo.

REM Step 1: Go to build/web folder
cd build\web

REM Step 2: Ask Python for a free port
for /f %%p in ('python -c "import socket;s=socket.socket();s.bind(('',0));print(s.getsockname()[1]);s.close()"') do (
    set PORT=%%p
)

echo Assigned Port: %PORT%
echo.

REM Step 3: Open browser on the dynamic port
start http://localhost:%PORT%

REM Step 4: Start Python server on that port
echo ========================================
echo Server started at http://localhost:%PORT%
echo Press Ctrl+C to stop the server
echo ========================================
echo.

python -m http.server %PORT%

echo.
echo Server stopped.
pause
