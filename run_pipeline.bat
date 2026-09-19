@echo off
REM ==============================================================================
REM run_pipeline.bat
REM Executes data ingestion via Python (kagglehub) and model training in R
REM ==============================================================================

echo ================================================================
echo Step 1: Downloading dataset from Kaggle via Python kagglehub...
echo ================================================================
python download_data.py
if %ERRORLEVEL% NEQ 0 (
    echo [NOTICE] Python download failed or kagglehub not configured.
    echo Generating sample dataset for testing...
    python sample_data_generator.py
)

echo.
echo ================================================================
echo Step 2: Running Linear Regression training pipeline in R...
echo ================================================================
where Rscript >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Rscript command not found in PATH!
    echo Please make sure R is installed and added to your system PATH.
    pause
    exit /b 1
)

Rscript train_model.R
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] R model training failed!
    pause
    exit /b 1
)

echo.
echo ================================================================
echo Step 3: Running sample predictions with the trained model...
echo ================================================================
Rscript predict.R

echo.
echo ================================================================
echo Pipeline finished successfully!
echo Results:
echo  - Model artifact:        book_rating_lm.rds
echo  - Evaluation metrics:    evaluation_metrics.csv
echo  - Model coefficients:    model_coefficients.csv
echo  - Diagnostic plots:      plots/model_diagnostics.png
echo                           plots/actual_vs_predicted.png
echo ================================================================
pause
