# ==============================================================================
# predict.R
# Predict Book Ratings using the trained Linear Regression Model
# ==============================================================================

model_file <- "book_rating_lm.rds"

if (!file.exists(model_file)) {
  cat("[ERROR] Model file 'book_rating_lm.rds' not found.\n")
  cat("Please run 'train_model.R' first to train and save the model.\n")
  quit(status = 1)
}

# Load the saved R model object
cat(sprintf("Loading trained model from '%s'...\n\n", model_file))
model <- readRDS(model_file)

# Display model formula
cat("Model Formula:\n")
print(formula(model))
cat("\n")

# Define a function to predict ratings for new books/users
predict_book_rating <- function(user_age, book_age, title_length, book_rating_count, author_book_count) {
  new_data <- data.frame(
    User_Age = as.numeric(user_age),
    Book_Age = as.numeric(book_age),
    Title_Length = as.numeric(title_length),
    log_Book_Rating_Count = log1p(as.numeric(book_rating_count)),
    log_Author_Book_Count = log1p(as.numeric(author_book_count))
  )
  
  # Fit with 95% Confidence and Prediction Intervals
  fit_pred <- predict(model, newdata = new_data, interval = "prediction", level = 0.95)
  fit_conf <- predict(model, newdata = new_data, interval = "confidence", level = 0.95)
  
  result <- data.frame(
    User_Age = user_age,
    Book_Age = book_age,
    Title_Length = title_length,
    Rating_Count = book_rating_count,
    Author_Book_Count = author_book_count,
    Predicted_Rating = round(fit_pred[, "fit"], 2),
    Conf_Lower_95 = round(fit_conf[, "lwr"], 2),
    Conf_Upper_95 = round(fit_conf[, "upr"], 2),
    Pred_Lower_95 = round(pmax(1, fit_pred[, "lwr"]), 2), # Bound within valid 1-10 range
    Pred_Upper_95 = round(pmin(10, fit_pred[, "upr"]), 2)
  )
  return(result)
}

# Example Scenarios:
cat("Evaluating Sample Prediction Scenarios:\n")
cat("--------------------------------------------------------------------------------\n")

sample_inputs <- data.frame(
  User_Age = c(22, 35, 60, 28),
  Book_Age = c(2, 25, 50, 1),
  Title_Length = c(15, 32, 22, 45),
  Book_Rating_Count = c(5, 350, 1200, 2),
  Author_Book_Count = c(1, 15, 30, 2)
)

predictions <- predict_book_rating(
  user_age = sample_inputs$User_Age,
  book_age = sample_inputs$Book_Age,
  title_length = sample_inputs$Title_Length,
  book_rating_count = sample_inputs$Book_Rating_Count,
  author_book_count = sample_inputs$Author_Book_Count
)

print(predictions, row.names = FALSE)
cat("--------------------------------------------------------------------------------\n")
cat("* Predicted_Rating: Expected rating on 1-10 scale.\n")
cat("* Conf_Lower/Upper: 95% confidence interval for the average rating.\n")
cat("* Pred_Lower/Upper: 95% prediction interval for an individual user rating.\n\n")
