@echo off
REM ==============================================================================
REM push_to_github.bat
REM Pushes the project repository to https://github.com/abhipansuriya60/book-model-r
REM ==============================================================================

echo ================================================================
echo Pushing repository to https://github.com/abhipansuriya60/book-model-r
echo ================================================================
echo.

git push -u origin main

echo.
if %ERRORLEVEL% EQU 0 (
    echo ================================================================
    echo [SUCCESS] Pushed successfully to GitHub!
    echo View repository: https://github.com/abhipansuriya60/book-model-r
    echo ================================================================
) else (
    echo ================================================================
    echo [NOTICE] If GitHub requested sign-in, please complete authentication
    echo in the browser window and re-run this script.
    echo ================================================================
)

pause
