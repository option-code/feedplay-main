@echo off
:: 🚀 Auto Git Commit & Push Script by Abdul Mueed (with Matrix intro)

:: Set text color: 0A = black background, bright green text
color 0A

:: Set terminal title
title 💻 MATRIX PUSH MODE - Abdul Mueed 🚀

:: 🌌 MATRIX RAIN ANIMATION
for /L %%n in (1,1,30) do (
    setlocal enabledelayedexpansion
    set "line="
    for /L %%i in (1,1,80) do (
        set /A "r=!random! %% 40"
        if !r! lss 10 (
            set "char=1"
        ) else if !r! lss 20 (
            set "char=0"
        ) else if !r! lss 25 (
            set "char=@"
        ) else if !r! lss 30 (
            set "char=$"
        ) else (
            set "char= "
        )
        set "line=!line!!char!"
    )
    echo !line!
    timeout /nobreak /t 0 >nul
    endlocal
)
cls

:: 🌟 Header after Matrix rain
echo ================================================
echo 👑  Abdul Mueed - Auto Git Push Utility
echo ================================================
echo.

:: 🧠 Show current git status
git status

echo.
echo ➕ Adding all changes...
git add .

:: Ask for commit message
set /p msg=💬 Enter commit message (default: "Auto update"): 
if "%msg%"=="" set msg=Auto update

echo.
echo 📝 Committing changes...
git commit -m "%msg%"

echo.
echo 🚀 Pushing to remote...
git push

echo.
echo ✅ All done! Pushed successfully, boss 😎
echo ================================================

pause
