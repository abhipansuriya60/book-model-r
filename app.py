"""
app.py
Flask Backend for Book Rating Linear Regression Web Application
Serves REST API and static frontend assets.
"""

import os
import csv
import math
from flask import Flask, request, jsonify, send_from_directory, render_template

app = Flask(__name__, static_folder="static")

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "data")
PLOTS_DIR = os.path.join(BASE_DIR, "plots")

# Model parameters (loaded from model_coefficients.csv or fallback to trained values)
MODEL_PARAMS = {
    "intercept": 6.8511159,
    "coef_user_age": 0.0038197,
    "coef_book_age": 0.0135791,
    "coef_title_length": 0.0001287,
    "coef_log_book_rating_count": 0.0879418,
    "coef_log_author_book_count": 0.0320556,
    "residual_se": 1.833,
    "train_n": 32946,
    "test_rmse": 1.8191,
    "test_mae": 1.4600,
    "r_squared": 0.00704
}

# Load coefficients from CSV if available
coef_file = os.path.join(BASE_DIR, "model_coefficients.csv")
if os.path.exists(coef_file):
    try:
        with open(coef_file, "r", encoding="utf-8") as f:
            reader = csv.reader(f)
            header = next(reader, None)
            for row in reader:
                if len(row) >= 2:
                    feat = row[0].strip()
                    val = float(row[1])
                    if feat == "(Intercept)":
                        MODEL_PARAMS["intercept"] = val
                    elif feat == "User_Age":
                        MODEL_PARAMS["coef_user_age"] = val
                    elif feat == "Book_Age":
                        MODEL_PARAMS["coef_book_age"] = val
                    elif feat == "Title_Length":
                        MODEL_PARAMS["coef_title_length"] = val
                    elif feat == "log_Book_Rating_Count":
                        MODEL_PARAMS["coef_log_book_rating_count"] = val
                    elif feat == "log_Author_Book_Count":
                        MODEL_PARAMS["coef_log_author_book_count"] = val
        print("[SUCCESS] Loaded model coefficients from model_coefficients.csv")
    except Exception as e:
        print(f"[WARNING] Could not load model_coefficients.csv: {e}")

# In-memory book catalog for fast search
BOOKS_INDEX = []

def load_books_index():
    global BOOKS_INDEX
    books_file = os.path.join(DATA_DIR, "Books.csv")
    if not os.path.exists(books_file):
        books_file = os.path.join(DATA_DIR, "books.csv")
    
    if not os.path.exists(books_file):
        print("[WARNING] Books.csv not found in data/. Search will return empty results.")
        return

    print(f"Indexing books from '{books_file}' for fast searching...")
    count = 0
    try:
        # Detect delimiter and load first 50,000 for responsive search
        with open(books_file, "r", encoding="latin1") as f:
            sample_line = f.readline()
            delim = ";" if sample_line.count(";") > sample_line.count(",") else ","
            f.seek(0)
            reader = csv.DictReader(f, delimiter=delim, quotechar='"')
            for row in reader:
                # Standardize keys
                cleaned_row = {k.replace("-", "_").replace(".", "_").strip(): v.strip('"') for k, v in row.items() if k}
                isbn = cleaned_row.get("ISBN", "")
                title = cleaned_row.get("Book_Title", "")
                author = cleaned_row.get("Book_Author", "")
                year = cleaned_row.get("Year_Of_Publication", "")
                publisher = cleaned_row.get("Publisher", "")
                img_m = cleaned_row.get("Image_URL_M", "")
                
                if title and isbn:
                    BOOKS_INDEX.append({
                        "isbn": isbn,
                        "title": title,
                        "author": author,
                        "year": year,
                        "publisher": publisher,
                        "image_url": img_m
                    })
                    count += 1
                    if count >= 60000:  # Keep 60k popular books in memory for snappy response
                        break
        print(f"[SUCCESS] Indexed {len(BOOKS_INDEX)} books in memory for live search.")
    except Exception as e:
        print(f"[ERROR] Failed to index books: {e}")

load_books_index()

# ----------------- ROUTES -----------------

@app.route("/")
def index():
    return send_from_directory(app.static_folder, "index.html")

@app.route("/plots/<path:filename>")
def serve_plots(filename):
    return send_from_directory(PLOTS_DIR, filename)

@app.route("/api/status", methods=["GET"])
def api_status():
    return jsonify({
        "status": "healthy",
        "model": "Multiple Linear Regression (lm)",
        "framework": "R 4.x + Python Flask",
        "dataset": "saurabhbagchi/books-dataset (Kaggle)",
        "indexed_books": len(BOOKS_INDEX),
        "features": [
            "User_Age", "Book_Age", "Title_Length",
            "log_Book_Rating_Count", "log_Author_Book_Count"
        ]
    })

@app.route("/api/metrics", methods=["GET"])
def api_metrics():
    metrics = []
    metrics_file = os.path.join(BASE_DIR, "evaluation_metrics.csv")
    if os.path.exists(metrics_file):
        try:
            with open(metrics_file, "r", encoding="utf-8") as f:
                reader = csv.DictReader(f)
                metrics = [row for row in reader]
        except Exception:
            pass

    coefficients = []
    if os.path.exists(coef_file):
        try:
            with open(coef_file, "r", encoding="utf-8") as f:
                reader = csv.reader(f)
                header = next(reader, None)
                for row in reader:
                    if len(row) >= 5:
                        coefficients.append({
                            "feature": row[0],
                            "estimate": float(row[1]),
                            "std_error": float(row[2]),
                            "t_value": float(row[3]),
                            "p_value": float(row[4])
                        })
        except Exception:
            pass

    return jsonify({
        "metrics": metrics,
        "coefficients": coefficients,
        "summary": {
            "formula": "Book_Rating ~ User_Age + Book_Age + Title_Length + log1p(Rating_Count) + log1p(Author_Count)",
            "test_rmse": MODEL_PARAMS["test_rmse"],
            "test_mae": MODEL_PARAMS["test_mae"],
            "train_r2": MODEL_PARAMS["r_squared"],
            "f_statistic": 46.72,
            "f_pvalue": "< 2.2e-16"
        }
    })

@app.route("/api/predict", methods=["POST"])
def api_predict():
    data = request.get_json() or {}

    try:
        user_age = float(data.get("user_age", 30))
        pub_year = float(data.get("publication_year", 2000))
        title = str(data.get("title", "Sample Book"))
        title_length = float(len(title.strip()))
        rating_count = max(0.0, float(data.get("rating_count", 25)))
        author_count = max(1.0, float(data.get("author_book_count", 5)))
    except (ValueError, TypeError) as e:
        return jsonify({"error": f"Invalid input parameters: {e}"}), 400

    current_year = 2026
    book_age = max(0.0, min(200.0, current_year - pub_year))
    log_rating_count = math.log1p(rating_count)
    log_author_count = math.log1p(author_count)

    # Compute contribution of each feature
    c_intercept = MODEL_PARAMS["intercept"]
    c_user_age = user_age * MODEL_PARAMS["coef_user_age"]
    c_book_age = book_age * MODEL_PARAMS["coef_book_age"]
    c_title = title_length * MODEL_PARAMS["coef_title_length"]
    c_ratings = log_rating_count * MODEL_PARAMS["coef_log_book_rating_count"]
    c_author = log_author_count * MODEL_PARAMS["coef_log_author_book_count"]

    raw_prediction = c_intercept + c_user_age + c_book_age + c_title + c_ratings + c_author
    predicted_rating = max(1.0, min(10.0, raw_prediction))

    # Standard error approximation
    # SE(mean) ~ sigma / sqrt(n) * leverage (~0.04)
    # SE(pred) ~ sqrt(sigma^2 + SE(mean)^2) ~ 1.833
    sigma = MODEL_PARAMS["residual_se"]
    se_mean = 0.05
    se_pred = math.sqrt(sigma**2 + se_mean**2)

    conf_lower = max(1.0, round(raw_prediction - 1.96 * se_mean, 2))
    conf_upper = min(10.0, round(raw_prediction + 1.96 * se_mean, 2))
    pred_lower = max(1.0, round(raw_prediction - 1.96 * se_pred, 2))
    pred_upper = min(10.0, round(raw_prediction + 1.96 * se_pred, 2))

    # Feature impact breakdown
    impacts = [
        {"feature": "Baseline (Intercept)", "value": round(c_intercept, 3), "type": "baseline"},
        {"feature": "User Age Effect", "value": round(c_user_age, 3), "type": "positive" if c_user_age >= 0 else "negative"},
        {"feature": "Book Age Effect", "value": round(c_book_age, 3), "type": "positive" if c_book_age >= 0 else "negative"},
        {"feature": "Title Length Effect", "value": round(c_title, 3), "type": "positive" if c_title >= 0 else "negative"},
        {"feature": "Review Popularity Effect", "value": round(c_ratings, 3), "type": "positive" if c_ratings >= 0 else "negative"},
        {"feature": "Author Catalog Effect", "value": round(c_author, 3), "type": "positive" if c_author >= 0 else "negative"}
    ]

    return jsonify({
        "predicted_rating": round(predicted_rating, 2),
        "raw_rating": round(raw_prediction, 3),
        "confidence_interval_95": {"lower": conf_lower, "upper": conf_upper},
        "prediction_interval_95": {"lower": pred_lower, "upper": pred_upper},
        "inputs": {
            "user_age": user_age,
            "publication_year": pub_year,
            "book_age": book_age,
            "title": title,
            "title_length": title_length,
            "rating_count": rating_count,
            "author_book_count": author_count
        },
        "impacts": impacts
    })

@app.route("/api/books", methods=["GET"])
def api_books():
    query = request.args.get("q", "").strip().lower()
    limit = min(50, max(1, int(request.args.get("limit", 20))))

    if not query:
        # Return popular selection of books
        return jsonify({"books": BOOKS_INDEX[:limit], "total": len(BOOKS_INDEX)})

    results = []
    for book in BOOKS_INDEX:
        if query in book["title"].lower() or query in book["author"].lower() or query in book["isbn"].lower():
            results.append(book)
            if len(results) >= limit:
                break

    return jsonify({"books": results, "total": len(results), "query": query})

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    print(f"Starting Book Rating Linear Regression Web App on http://127.0.0.1:{port}")
    app.run(host="127.0.0.1", port=port, debug=False)
