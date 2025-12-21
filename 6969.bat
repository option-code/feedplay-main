@echo off
echo ========================================
echo Run Python Server in build/web
echo ========================================
echo.

REM Step 1: First go to the build/web folder
cd build\web

REM Step 2: Open the browser at localhost:9090
start http://localhost:9090

REM Step 3: Run Python server in foreground so it can be properly terminated
echo.
echo ========================================
echo Server started at http://localhost:9090
echo Press Ctrl+C to stop the server
echo ========================================
echo.

python -m http.server 9090

echo.
echo Server stopped.
echo.
pause