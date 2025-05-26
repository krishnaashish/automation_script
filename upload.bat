@echo off
setlocal

echo Starting FTP upload using WinSCP PowerShell script...
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\mwscript\upload_files.ps1"

echo Upload process finished.
echo.
echo === Upload complete. Closing in 10 seconds... ===
timeout /t 10 /nobreak >nul
