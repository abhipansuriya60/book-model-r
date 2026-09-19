"""
download_data.py
Downloads the saurabhbagchi/books-dataset from Kaggle using kagglehub,
and copies the CSV files into a local 'data/' directory for R processing.
"""

import os
import shutil
import sys

def download_and_extract():
    print("=" * 60)
    print("Downloading dataset: saurabhbagchi/books-dataset via kagglehub...")
    print("=" * 60)

    try:
        import kagglehub
    except ImportError:
        print("[ERROR] 'kagglehub' package is not installed.")
        print("Please install it using: pip install kagglehub")
        sys.exit(1)

    # Download latest version
    try:
        path = kagglehub.dataset_download("saurabhbagchi/books-dataset")
        print(f"[SUCCESS] Downloaded dataset to cache: {path}")
    except Exception as e:
        print(f"[ERROR] Failed to download dataset via kagglehub: {e}")
        sys.exit(1)

    # Prepare local data directory
    target_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
    os.makedirs(target_dir, exist_ok=True)
    print(f"\nCopying CSV files to target directory: {target_dir}")

    # Walk through downloaded folder and copy CSV files
    copied_count = 0
    for root, _, files in os.walk(path):
        for file in files:
            if file.lower().endswith(".csv"):
                src_file = os.path.join(root, file)
                dest_file = os.path.join(target_dir, file)
                print(f" -> Copying: {file} ({os.path.getsize(src_file) / (1024*1024):.2f} MB)")
                shutil.copy2(src_file, dest_file)
                copied_count += 1

    if copied_count == 0:
        print("[WARNING] No .csv files were found in the downloaded directory.")
    else:
        print(f"\n[DONE] Successfully copied {copied_count} CSV file(s) to '{target_dir}'.")
        print("Files ready for R model training:")
        for f in os.listdir(target_dir):
            if f.lower().endswith(".csv"):
                size_mb = os.path.getsize(os.path.join(target_dir, f)) / (1024*1024)
                print(f"  - {f} ({size_mb:.2f} MB)")

if __name__ == "__main__":
    download_and_extract()
