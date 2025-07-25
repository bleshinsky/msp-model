@echo off
REM MSP Git Repository Setup - Windows Batch Script
REM Run this from C:\__gh\msp directory

echo ========================================
echo     MSP Git Repository Setup
echo ========================================
echo.

REM Check if Git is installed
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Git is not installed!
    echo Please install Git from: https://git-scm.com
    echo.
    pause
    exit /b 1
)

echo Git is installed.
echo.

REM Initialize repository
echo Initializing Git repository...
git init
if %errorlevel% neq 0 (
    echo ERROR: Failed to initialize Git repository
    pause
    exit /b 1
)

echo.
echo Adding all files...
git add -A

echo.
echo Creating initial commit...
git commit -m "Initial commit: MSP (Mandatory Session Protocol)" -m "" -m "MSP is a developer productivity tool for structured session management." -m "" -m "Features:" -m "- MSP Lite: Zero-dependency quick start version" -m "- MSP Standard: Full NOL Framework (Neo4j + Obsidian + Linear)" -m "- MSP Advanced: Enterprise features for teams" -m "" -m "Version: 1.0.0" -m "License: MIT"

echo.
echo ========================================
echo Git repository initialized successfully!
echo ========================================
echo.
echo Next steps:
echo.
echo 1. Create a new repository on GitHub:
echo    https://github.com/new
echo    Name: msp
echo    Description: MSP - Mandatory Session Protocol: Never lose context again
echo    Public: Yes
echo    Don't initialize with README/license/.gitignore
echo.
echo 2. After creating, run these commands:
echo    git remote add origin https://github.com/bleshik/msp.git
echo    git branch -M main
echo    git push -u origin main
echo.
echo See GIT-SETUP-COMMANDS.md for detailed instructions.
echo.
pause