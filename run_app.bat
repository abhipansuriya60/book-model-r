@echo off
REM ==============================================================================
REM run_app.bat
REM Starts the Flask backend server and opens the web application in your browser
REM ==============================================================================

echo ================================================================
echo Starting BookIQ Linear Regression Web Application...
echo ================================================================

start http://127.0.0.1:5000
python app.py

pause
