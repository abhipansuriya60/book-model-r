"""
sample_data_generator.py
Generates a representative synthetic sample of Books.csv, Ratings.csv, and Users.csv
in data/ directory for instant verification and testing of the R pipeline.
"""

import os
import random

def generate_sample_data(num_books=200, num_users=500, num_ratings=2500):
    data_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
    os.makedirs(data_dir, exist_ok=True)

    print(f"Generating sample dataset in '{data_dir}'...")

    authors = [
        "J.K. Rowling", "George R.R. Martin", "Stephen King", "Agatha Christie",
        "J.R.R. Tolkien", "Isaac Asimov", "Dan Brown", "Neil Gaiman",
        "Haruki Murakami", "Jane Austen", "Mark Twain", "Ernest Hemingway"
    ]

    publishers = [
        "Penguin Books", "HarperCollins", "Random House", "Simon & Schuster",
        "Macmillan", "Hachette", "Vintage", "Oxford University Press"
    ]

    title_words = [
        "The", "Secret", "Chronicles", "Journey", "Shadow", "Night", "Wind",
        "Stars", "Empire", "Silent", "Lost", "Dream", "Time", "Fire", "Darkness"
    ]

    # 1. Generate Books.csv
    books_file = os.path.join(data_dir, "Books.csv")
    isbns = []
    with open(books_file, "w", encoding="latin-1", newline="") as f:
        # Header matching Kaggle dataset
        f.write('"ISBN";"Book-Title";"Book-Author";"Year-Of-Publication";"Publisher";"Image-URL-S";"Image-URL-M";"Image-URL-L"\n')
        for i in range(1, num_books + 1):
            isbn = f"0{random.randint(100000000, 999999999)}"
            isbns.append(isbn)
            title = " ".join(random.sample(title_words, k=random.randint(2, 4))) + f" Vol. {random.randint(1, 5)}"
            author = random.choice(authors)
            year = random.randint(1970, 2024)
            publisher = random.choice(publishers)
            img_s = f"http://images.amazon.com/images/P/{isbn}.01.THUMBZZZ.jpg"
            img_m = f"http://images.amazon.com/images/P/{isbn}.01.MZZZZZZZ.jpg"
            img_l = f"http://images.amazon.com/images/P/{isbn}.01.LZZZZZZZ.jpg"
            f.write(f'"{isbn}";"{title}";"{author}";"{year}";"{publisher}";"{img_s}";"{img_m}";"{img_l}"\n')

    # 2. Generate Users.csv
    users_file = os.path.join(data_dir, "Users.csv")
    locations = [
        "new york, new york, usa", "london, england, united kingdom",
        "toronto, ontario, canada", "sydney, new south wales, australia",
        "berlin, berlin, germany", "mumbai, maharashtra, india",
        "paris, ile-de-france, france", "chicago, illinois, usa"
    ]
    user_ids = list(range(1001, 1001 + num_users))
    with open(users_file, "w", encoding="latin-1", newline="") as f:
        f.write('"User-ID";"Location";"Age"\n')
        for uid in user_ids:
            loc = random.choice(locations)
            # Some users have missing age, others have realistic age
            if random.random() < 0.15:
                age_str = "NULL"
            else:
                age_str = str(random.randint(18, 72))
            f.write(f'"{uid}";"{loc}";"{age_str}"\n')

    # 3. Generate Ratings.csv
    ratings_file = os.path.join(data_dir, "Ratings.csv")
    with open(ratings_file, "w", encoding="latin-1", newline="") as f:
        f.write('"User-ID";"ISBN";"Book-Rating"\n')
        existing_pairs = set()
        count = 0
        while count < num_ratings:
            uid = random.choice(user_ids)
            isbn = random.choice(isbns)
            if (uid, isbn) in existing_pairs:
                continue
            existing_pairs.add((uid, isbn))
            # Ratings: mix of explicit (1-10) and implicit (0)
            if random.random() < 0.2:
                rating = 0
            else:
                # Slight skew towards higher ratings typical of book ratings (6-9)
                rating = random.choices([1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
                                        weights=[2, 3, 5, 7, 10, 15, 20, 25, 20, 15])[0]
            f.write(f'"{uid}";"{isbn}";"{rating}"\n')
            count += 1

    print(f"[SUCCESS] Sample data generated:")
    print(f" - {books_file} ({num_books} books)")
    print(f" - {users_file} ({num_users} users)")
    print(f" - {ratings_file} ({num_ratings} ratings)")

if __name__ == "__main__":
    generate_sample_data()
