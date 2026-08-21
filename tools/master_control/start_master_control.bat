@echo off
title NAMPO GOGO MASTER CONTROL LAUNCHER
echo ===================================================
echo   NAMPO GOGO MASTER CONTROL v2 LAUNCHER
echo   (Localhost 127.0.0.1:18888 Read-Only Dashboard)
echo ===================================================

cd /d "D:\dev\Nampo_GoGo_Project"

echo.
echo Starting Master Control Dashboard server...
start /b python tools/master_control/master_control.py serve

timeout /t 2 >nul

echo Opening browser at http://127.0.0.1:18888 ...
start http://127.0.0.1:18888

echo.
echo Master Control Server is running.
echo Press Ctrl+C or close this window to exit.
