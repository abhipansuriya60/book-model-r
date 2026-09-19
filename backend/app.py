"""
backend/app.py
Convenience launcher allowing 'python backend/app.py' to run the main application.
"""

import os
import sys

# Ensure root directory is in python path and is current working directory
root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, root_dir)
os.chdir(root_dir)

from app import app

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    print(f"Starting Book Rating Linear Regression Web App from backend/ on port {port}...")
    app.run(host="0.0.0.0", port=port, debug=False)
