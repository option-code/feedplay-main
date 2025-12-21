@echo off
echo ========================================
echo Kill Python Servers on Multiple Ports
echo ========================================
echo.

:LOOP
set /p PORT=Enter port number to kill (leave blank to exit): 

if "%PORT%"=="" (
    echo No port entered. Exiting...
    pause
    exit /b
)

echo Finding Python server on port %PORT%...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :%PORT% ^| findstr LISTENING') do (
    echo Killing Python server with PID %%a
    taskkill /f /pid %%a
)

echo Server on port %PORT% killed (if it existed).
echo.

goto LOOP
