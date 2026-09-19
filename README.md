# Book Rating Linear Regression Laboratory & Web Application

An end-to-end Machine Learning and Web Application powered by **R** (`lm`), **Python Flask**, and a modern **interactive web frontend** on the **saurabhbagchi/books-dataset** from Kaggle.

---

## 📁 Project Structure

```
project/
├── app.py                      # Flask REST API backend & static file server
├── static/
│   ├── index.html              # Modern dark-mode single page web interface
│   ├── style.css               # Glassmorphism design system, responsive layouts
│   └── app.js                  # Reactive sliders, SVG gauge animation, book search
├── train_model.R               # Main R script: Preprocessing, lm() training, diagnostics
├── predict.R                   # R CLI script: loads book_rating_lm.rds and makes predictions
├── download_data.py            # Python script: downloads dataset via kagglehub into data/
├── sample_data_generator.py    # Generates synthetic sample CSVs for quick offline testing
├── run_app.bat                 # One-click launcher for the Web Application
├── run_pipeline.bat            # Windows batch script to run python download + R training
├── data/                       # Contains Books.csv, Ratings.csv, Users.csv
├── plots/                      # Generated visual diagnostic plots
│   ├── model_diagnostics.png   # Residuals vs Fitted & Normal Q-Q plots
│   └── actual_vs_predicted.png # Test set actual vs predicted scatter plot
├── book_rating_lm.rds          # Trained serialized R model object
├── evaluation_metrics.csv      # Model metrics (R², RMSE, MAE)
└── model_coefficients.csv      # Fitted coefficients, t-stats, and p-values
```

---

## 🌐 Running the Web Application

To launch the web application:
```cmd
run_app.bat
```
or run directly from terminal:
```bash
python app.py
```
Open **`http://127.0.0.1:5000`** in your browser.

### Key Web Features:
1. **Interactive Rating Predictor**:
   - Real-time sliders for **Reviewer Age**, **Publication Year**, **Review Popularity**, and **Author Catalog Size**.
   - Live title length detection.
   - Quick-load presets: *Timeless Classic*, *Viral Bestseller*, *Debut Indie Release*, *Academic Text*.
   - **Animated Circular SVG Score Gauge** (1.0 to 10.0) with dynamic verdict.
   - **95% Confidence Interval** (expected average rating) and **95% Prediction Interval** (individual review).
   - **Regression Factor Contribution Waterfall Chart** showing exact point breakdown ($\beta_i \cdot x_i$).
2. **Search 115,000+ Kaggle Books**:
   - Instant search across indexed titles and authors.
   - Displays real book covers (`Image-URL-M`), authors, and publication years.
   - **"Predict for This Book"** button auto-populates the predictor with one click.
3. **Model Diagnostics & Evaluation Dashboard**:
   - Key evaluation metrics: Test RMSE (`1.8191`), MAE (`1.4600`), $F$-statistic (`46.72`, $p < 2.2 \times 10^{-16}$).
   - Parameter estimates table with $p$-values and significance levels (`***`).
   - High-resolution embedded diagnostic plots.

---

## 🔌 REST API Endpoints

- `GET /` — Web interface
- `GET /api/status` — Backend health, dataset size, and model state
- `POST /api/predict` — Computes predicted rating, intervals, and factor contributions:
  ```json
  {
    "title": "The Hobbit",
    "user_age": 35,
    "publication_year": 1937,
    "rating_count": 800,
    "author_book_count": 25
  }
  ```
- `GET /api/books?q=potter&limit=20` — Searches indexed books in memory
- `GET /api/metrics` — Returns model coefficients and evaluation metrics
- `GET /plots/<filename>` — Serves diagnostic plot images

---

## 🔬 Model Training in R

If you wish to re-train the model directly in R:
```bash
Rscript train_model.R
```
This reads `data/Books.csv`, `data/Ratings.csv`, and `data/Users.csv`, fits `lm()`, exports `book_rating_lm.rds`, saves diagnostic plots into `plots/`, and outputs `evaluation_metrics.csv`.
