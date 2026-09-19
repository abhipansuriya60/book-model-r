# ==============================================================================
# train_model.R
# Linear Regression Model for Book Rating Prediction in R
# Dataset: Books, Ratings, and Users (saurabhbagchi/books-dataset)
# ==============================================================================

cat("=================================================================\n")
cat("   Book Rating Prediction - Linear Regression Training Pipeline   \n")
cat("=================================================================\n\n")

# 1. Helper Functions
find_file <- function(filename) {
  candidates <- c(
    file.path("data", filename),
    file.path("data", tolower(filename)),
    filename,
    tolower(filename)
  )
  for (c in candidates) {
    if (file.exists(c)) return(c)
  }
  return(NULL)
}

detect_delimiter <- function(filepath) {
  first_line <- readLines(filepath, n = 1, warn = FALSE)
  semicolons <- length(gregexpr(";", first_line)[[1]])
  commas <- length(gregexpr(",", first_line)[[1]])
  if (semicolons > commas) return(";")
  return(",")
}

read_csv_robust <- function(filepath, nrows = -1) {
  delim <- detect_delimiter(filepath)
  cat(sprintf("Loading '%s' (delimiter: '%s')...\n", filepath, delim))
  
  # Try Latin-1 first (standard for Book-Crossing dataset), fallback to default
  df <- tryCatch({
    read.csv(
      filepath,
      sep = delim,
      quote = "\"",
      stringsAsFactors = FALSE,
      fileEncoding = "latin1",
      nrows = nrows,
      check.names = TRUE
    )
  }, error = function(e) {
    read.csv(
      filepath,
      sep = delim,
      quote = "\"",
      stringsAsFactors = FALSE,
      nrows = nrows,
      check.names = TRUE
    )
  })
  return(df)
}

# 2. Locate Data Files
books_path <- find_file("Books.csv")
ratings_path <- find_file("Ratings.csv")
users_path <- find_file("Users.csv")

if (is.null(books_path) || is.null(ratings_path) || is.null(users_path)) {
  cat("\n[ERROR] One or more required CSV files were not found in 'data/' or current directory.\n")
  cat("Expected files: Books.csv, Ratings.csv, Users.csv\n")
  cat("Please run 'python download_data.py' or 'python sample_data_generator.py' first.\n")
  quit(status = 1)
}

cat(sprintf("Found Books:   %s\n", books_path))
cat(sprintf("Found Ratings: %s\n", ratings_path))
cat(sprintf("Found Users:   %s\n\n", users_path))

# 3. Load Datasets
books <- read_csv_robust(books_path)
ratings <- read_csv_robust(ratings_path)
users <- read_csv_robust(users_path)

cat(sprintf("\nRaw Record Counts:\n - Books:   %d rows\n - Ratings: %d rows\n - Users:   %d rows\n\n",
            nrow(books), nrow(ratings), nrow(users)))

# 4. Standardize Column Names
# Handles cases like Book.Rating vs Book-Rating vs ISBN
standardize_cols <- function(df) {
  names(df) <- gsub("[.-]", "_", names(df))
  return(df)
}

books <- standardize_cols(books)
ratings <- standardize_cols(ratings)
users <- standardize_cols(users)

# 5. Data Cleaning & Feature Engineering

cat("-----------------------------------------------------------------\n")
cat("Preprocessing & Engineering Features...\n")
cat("-----------------------------------------------------------------\n")

# Filter ratings: Focus on explicit ratings (1 to 10)
# (In Book-Crossing, 0 represents implicit interaction/unrated)
ratings$Book_Rating <- suppressWarnings(as.numeric(ratings$Book_Rating))
ratings <- ratings[!is.na(ratings$Book_Rating) & ratings$Book_Rating > 0 & ratings$Book_Rating <= 10, ]
cat(sprintf("Explicit Ratings (1-10): %d rows\n", nrow(ratings)))

# Clean Books
books$Year_Of_Publication <- suppressWarnings(as.numeric(books$Year_Of_Publication))
current_year <- 2026
# Filter reasonable publication years
books$Book_Age <- current_year - books$Year_Of_Publication
books$Book_Age[is.na(books$Book_Age) | books$Book_Age < 0 | books$Book_Age > 200] <- NA

# Title length
books$Title_Length <- nchar(as.character(books$Book_Title))
books$Title_Length[is.na(books$Title_Length)] <- median(books$Title_Length, na.rm = TRUE)

# Author Book Count (Productivity/Catalog size)
author_counts <- table(books$Book_Author)
books$Author_Book_Count <- as.numeric(author_counts[as.character(books$Book_Author)])
books$Author_Book_Count[is.na(books$Author_Book_Count)] <- 1

# Clean Users
users$Age <- suppressWarnings(as.numeric(users$Age))
# Filter realistic ages (10 to 100)
valid_ages <- users$Age >= 10 & users$Age <= 100 & !is.na(users$Age)
median_user_age <- median(users$Age[valid_ages], na.rm = TRUE)
if (is.na(median_user_age)) median_user_age <- 34
users$User_Age <- users$Age
users$User_Age[!valid_ages] <- median_user_age

# Rating count per book (Popularity / Social Proof)
book_rating_counts <- as.data.frame(table(ratings$ISBN))
colnames(book_rating_counts) <- c("ISBN", "Book_Rating_Count")

# 6. Merge Data
cat("Merging Ratings, Books, and Users...\n")
merged <- merge(ratings, books[, c("ISBN", "Book_Age", "Title_Length", "Author_Book_Count")], by = "ISBN")
merged <- merge(merged, users[, c("User_ID", "User_Age")], by = "User_ID")
merged <- merge(merged, book_rating_counts, by = "ISBN", all.x = TRUE)
merged$Book_Rating_Count[is.na(merged$Book_Rating_Count)] <- 1

# Impute median Book_Age if missing
median_book_age <- median(merged$Book_Age, na.rm = TRUE)
if (is.na(median_book_age)) median_book_age <- 20
merged$Book_Age[is.na(merged$Book_Age)] <- median_book_age

# Log-transform skewed counts
merged$log_Book_Rating_Count <- log1p(merged$Book_Rating_Count)
merged$log_Author_Book_Count <- log1p(merged$Author_Book_Count)

# Keep complete cases for model features
model_df <- merged[, c("Book_Rating", "User_Age", "Book_Age", "Title_Length",
                      "log_Book_Rating_Count", "log_Author_Book_Count")]
model_df <- model_df[complete.cases(model_df), ]

cat(sprintf("Final Preprocessed Dataset: %d observations with 5 predictor features.\n\n", nrow(model_df)))

# 7. Train / Test Split (80% Train, 20% Test)
set.seed(42)
train_indices <- sample(seq_len(nrow(model_df)), size = floor(0.80 * nrow(model_df)))
train_data <- model_df[train_indices, ]
test_data  <- model_df[-train_indices, ]

cat(sprintf("Training Set:   %d observations\n", nrow(train_data)))
cat(sprintf("Testing Set:    %d observations\n\n", nrow(test_data)))

# 8. Fit Multiple Linear Regression Model
cat("-----------------------------------------------------------------\n")
cat("Fitting Multiple Linear Regression Model (lm)...\n")
cat("-----------------------------------------------------------------\n")

model_formula <- Book_Rating ~ User_Age + Book_Age + Title_Length + log_Book_Rating_Count + log_Author_Book_Count
lm_model <- lm(model_formula, data = train_data)

# Print Summary
cat("\nModel Summary & Parameter Estimates:\n")
model_summary <- summary(lm_model)
print(model_summary)

# 9. Model Evaluation on Test Data
cat("\n-----------------------------------------------------------------\n")
cat("Evaluating on Held-Out Test Data...\n")
cat("-----------------------------------------------------------------\n")

test_predictions <- predict(lm_model, newdata = test_data)

# Calculate Metrics
residuals_test <- test_data$Book_Rating - test_predictions
test_rmse <- sqrt(mean(residuals_test^2))
test_mae  <- mean(abs(residuals_test))
ss_total  <- sum((test_data$Book_Rating - mean(test_data$Book_Rating))^2)
ss_res    <- sum(residuals_test^2)
test_r2   <- 1 - (ss_res / ss_total)

train_r2     <- model_summary$r.squared
train_adj_r2 <- model_summary$adj.r.squared
train_fstat  <- model_summary$fstatistic[1]

cat(sprintf("Train R-squared:          %.5f\n", train_r2))
cat(sprintf("Train Adjusted R-squared: %.5f\n", train_adj_r2))
cat(sprintf("Test R-squared:           %.5f\n", test_r2))
cat(sprintf("Test RMSE:                %.4f\n", test_rmse))
cat(sprintf("Test MAE:                 %.4f\n", test_mae))
cat("-----------------------------------------------------------------\n\n")

# 10. Generate and Save Diagnostic Plots
output_plot_dir <- "plots"
if (!dir.exists(output_plot_dir)) dir.create(output_plot_dir, recursive = TRUE)

# Plot 1: Residuals vs Fitted & Normal Q-Q
plot_file_diag <- file.path(output_plot_dir, "model_diagnostics.png")
png(filename = plot_file_diag, width = 1200, height = 600, res = 120)
par(mfrow = c(1, 2), mar = c(4.5, 4.5, 3, 2))

# Residuals vs Fitted
plot(
  fitted(lm_model), resid(lm_model),
  pch = 16, col = rgb(0.1, 0.4, 0.8, 0.3),
  xlab = "Fitted Values (Predicted Rating)",
  ylab = "Residuals",
  main = "Residuals vs Fitted"
)
abline(h = 0, col = "red", lty = 2, lwd = 2)

# Normal Q-Q Plot
qqnorm(
  resid(lm_model),
  pch = 16, col = rgb(0.2, 0.7, 0.3, 0.3),
  main = "Normal Q-Q Plot"
)
qqline(resid(lm_model), col = "red", lwd = 2)
dev.off()
cat(sprintf("[SAVED] Diagnostic plots saved to '%s'\n", plot_file_diag))

# Plot 2: Actual vs Predicted on Test Data
plot_file_pred <- file.path(output_plot_dir, "actual_vs_predicted.png")
png(filename = plot_file_pred, width = 700, height = 650, res = 120)
par(mar = c(4.5, 4.5, 3, 2))

# Plot sample of test data if large
sample_n <- min(5000, nrow(test_data))
sample_idx <- sample(seq_len(nrow(test_data)), sample_n)

plot(
  test_data$Book_Rating[sample_idx], test_predictions[sample_idx],
  pch = 16, col = rgb(0.4, 0.2, 0.7, 0.3),
  xlab = "Actual Rating (1 - 10)",
  ylab = "Predicted Rating",
  main = "Actual vs. Predicted Book Ratings (Test Set)",
  xlim = c(1, 10), ylim = c(1, 10)
)
abline(a = 0, b = 1, col = "darkorange", lwd = 2, lty = 2)
grid()
dev.off()
cat(sprintf("[SAVED] Actual vs Predicted plot saved to '%s'\n", plot_file_pred))

# 11. Save Metrics and Model Artifacts
metrics_df <- data.frame(
  Metric = c("Train_R2", "Train_Adj_R2", "Test_R2", "Test_RMSE", "Test_MAE", "Observations_Train", "Observations_Test"),
  Value  = c(train_r2, train_adj_r2, test_r2, test_rmse, test_mae, nrow(train_data), nrow(test_data))
)
write.csv(metrics_df, "evaluation_metrics.csv", row.names = FALSE)
cat("[SAVED] Model metrics saved to 'evaluation_metrics.csv'\n")

# Save Coefficients table
coef_table <- as.data.frame(model_summary$coefficients)
write.csv(coef_table, "model_coefficients.csv", row.names = TRUE)
cat("[SAVED] Model coefficients saved to 'model_coefficients.csv'\n")

# Save Trained Model Object for Deployment / Predictions
saveRDS(lm_model, file = "book_rating_lm.rds")
cat("[SAVED] Trained model serialized and saved to 'book_rating_lm.rds'\n")

cat("\n=================================================================\n")
cat("   Linear Regression Training Pipeline Completed Successfully!   \n")
cat("=================================================================\n")
