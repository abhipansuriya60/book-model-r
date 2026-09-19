/**
 * app.js
 * Frontend JavaScript for BookIQ Linear Regression Web Application
 */

document.addEventListener("DOMContentLoaded", () => {
  // DOM Elements
  const tabs = document.querySelectorAll(".tab-btn");
  const tabContents = document.querySelectorAll(".tab-content");

  // Inputs & Badges
  const inputTitle = document.getElementById("input-book-title");
  const inputUserAge = document.getElementById("input-user-age");
  const inputPubYear = document.getElementById("input-pub-year");
  const inputRatingCount = document.getElementById("input-rating-count");
  const inputAuthorCount = document.getElementById("input-author-count");
  const btnRecalculate = document.getElementById("btn-recalculate");

  const badgeTitle = document.getElementById("badge-title-length");
  const badgeUserAge = document.getElementById("badge-user-age");
  const badgePubYear = document.getElementById("badge-pub-year");
  const badgeRatingCount = document.getElementById("badge-rating-count");
  const badgeAuthorCount = document.getElementById("badge-author-count");

  // Outputs
  const gaugeCircle = document.getElementById("gauge-circle");
  const scoreDisplay = document.getElementById("predicted-score-display");
  const verdictText = document.getElementById("rating-verdict-text");
  const verdictSub = document.getElementById("rating-verdict-sub");
  const confIntervalText = document.getElementById("conf-interval-text");
  const confBarFill = document.getElementById("conf-bar-fill");
  const predIntervalText = document.getElementById("pred-interval-text");
  const predBarFill = document.getElementById("pred-bar-fill");
  const impactsList = document.getElementById("impacts-list");

  // Book Search Elements
  const inputSearch = document.getElementById("input-book-search");
  const booksGrid = document.getElementById("books-grid");

  // Diagnostics Elements
  const coefTbody = document.getElementById("coefficients-tbody");

  // -------------------------------------------------------------
  // 1. Tab Switching
  // -------------------------------------------------------------
  tabs.forEach((tab) => {
    tab.addEventListener("click", () => {
      tabs.forEach((t) => t.classList.remove("active"));
      tabContents.forEach((tc) => tc.classList.remove("active"));

      tab.classList.add("active");
      const targetId = tab.getAttribute("data-tab");
      const targetContent = document.getElementById(targetId);
      if (targetContent) {
        targetContent.classList.add("active");
      }

      if (targetId === "tab-analytics") {
        loadMetrics();
      } else if (targetId === "tab-search" && booksGrid.children.length === 0) {
        performSearch("Harry Potter");
      }
    });
  });

  // -------------------------------------------------------------
  // 2. Presets
  // -------------------------------------------------------------
  const presets = {
    classic: {
      title: "The Lord of the Rings: The Fellowship of the Ring",
      userAge: 42,
      year: 1954,
      ratings: 950,
      authorCount: 28,
    },
    bestseller: {
      title: "The Da Vinci Code: Special Illustrated Edition",
      userAge: 32,
      year: 2003,
      ratings: 1450,
      authorCount: 10,
    },
    indie: {
      title: "Silent Echoes in Neon Skies",
      userAge: 25,
      year: 2024,
      ratings: 18,
      authorCount: 2,
    },
    handbook: {
      title: "An Introduction to Statistical Learning with Applications in R",
      userAge: 52,
      year: 2013,
      ratings: 85,
      authorCount: 6,
    },
  };

  document.querySelectorAll(".preset-chip").forEach((chip) => {
    chip.addEventListener("click", () => {
      const pKey = chip.getAttribute("data-preset");
      const p = presets[pKey];
      if (p) {
        inputTitle.value = p.title;
        inputUserAge.value = p.userAge;
        inputPubYear.value = p.year;
        inputRatingCount.value = p.ratings;
        inputAuthorCount.value = p.authorCount;
        updateInputBadges();
        triggerPrediction();
      }
    });
  });

  // -------------------------------------------------------------
  // 3. Reactive Badges and Input Event Handlers
  // -------------------------------------------------------------
  function updateInputBadges() {
    const titleLen = inputTitle.value.trim().length;
    badgeTitle.textContent = `${titleLen} characters`;

    const userAge = inputUserAge.value;
    badgeUserAge.textContent = `${userAge} years`;

    const pubYear = parseInt(inputPubYear.value);
    const bookAge = Math.max(0, 2026 - pubYear);
    badgePubYear.textContent = `${pubYear} (${bookAge} yrs old)`;

    const ratings = inputRatingCount.value;
    badgeRatingCount.textContent = `${ratings} reviews`;

    const authorCount = inputAuthorCount.value;
    badgeAuthorCount.textContent = `${authorCount} books`;
  }

  let debounceTimer = null;
  function handleInputDebounced() {
    updateInputBadges();
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(() => {
      triggerPrediction();
    }, 150);
  }

  [inputUserAge, inputPubYear, inputRatingCount, inputAuthorCount].forEach((el) => {
    el.addEventListener("input", handleInputDebounced);
  });
  inputTitle.addEventListener("input", handleInputDebounced);
  btnRecalculate.addEventListener("click", triggerPrediction);

  // -------------------------------------------------------------
  // 4. Model Prediction API Call
  // -------------------------------------------------------------
  async function triggerPrediction() {
    const payload = {
      title: inputTitle.value.trim(),
      user_age: parseFloat(inputUserAge.value),
      publication_year: parseFloat(inputPubYear.value),
      rating_count: parseFloat(inputRatingCount.value),
      author_book_count: parseFloat(inputAuthorCount.value),
    };

    try {
      const res = await fetch("/api/predict", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      if (!res.ok) throw new Error("Failed to compute prediction");
      const data = await res.json();
      renderPrediction(data);
    } catch (err) {
      console.error("Prediction error:", err);
    }
  }

  function renderPrediction(data) {
    const rating = data.predicted_rating;

    // 1. Animate Gauge Meter (Circumference of r=75 is 2 * PI * 75 ~= 471.2)
    const maxCircumference = 471.2;
    // Map rating (1 to 10) to progress (0 to maxCircumference)
    const progress = Math.min(1.0, Math.max(0.0, (rating - 1) / 9));
    const strokeOffset = maxCircumference * (1 - progress);
    gaugeCircle.style.strokeDasharray = `${maxCircumference}`;
    gaugeCircle.style.strokeDashoffset = `${strokeOffset}`;

    // Animate Number
    scoreDisplay.textContent = rating.toFixed(2);

    // Dynamic Verdict
    if (rating >= 8.2) {
      verdictText.textContent = "Exceptional Masterpiece";
      verdictText.style.color = "#10b981";
      verdictSub.textContent = "Very high acclaim with solid reader consensus and strong longevity.";
    } else if (rating >= 7.8) {
      verdictText.textContent = "Highly Recommended";
      verdictText.style.color = "#8b5cf6";
      verdictSub.textContent = "Consistently praised with favorable critical and reader response.";
    } else if (rating >= 7.3) {
      verdictText.textContent = "Solid & Well-Received";
      verdictText.style.color = "#38bdf8";
      verdictSub.textContent = "Generally positive feedback across typical book reader demographics.";
    } else if (rating >= 6.9) {
      verdictText.textContent = "Moderate / Balanced";
      verdictText.style.color = "#f59e0b";
      verdictSub.textContent = "Mixed reader reactions or niche audience appeal.";
    } else {
      verdictText.textContent = "Divisive / Critical";
      verdictText.style.color = "#ef4444";
      verdictSub.textContent = "Lower consensus with polarized reviewer feedback.";
    }

    // 2. Confidence & Prediction Intervals
    const conf = data.confidence_interval_95;
    const pred = data.prediction_interval_95;

    confIntervalText.textContent = `[${conf.lower.toFixed(2)} — ${conf.upper.toFixed(2)}]`;
    predIntervalText.textContent = `[${pred.lower.toFixed(2)} — ${pred.upper.toFixed(2)}]`;

    // Map to percentage [1, 10]
    const confLeftPct = ((conf.lower - 1) / 9) * 100;
    const confWidthPct = Math.max(4, ((conf.upper - conf.lower) / 9) * 100);
    confBarFill.style.left = `${confLeftPct}%`;
    confBarFill.style.width = `${confWidthPct}%`;

    const predLeftPct = ((pred.lower - 1) / 9) * 100;
    const predWidthPct = Math.max(5, ((pred.upper - pred.lower) / 9) * 100);
    predBarFill.style.left = `${predLeftPct}%`;
    predBarFill.style.width = `${predWidthPct}%`;

    // 3. Feature Impacts Breakdown
    renderImpacts(data.impacts);
  }

  function renderImpacts(impacts) {
    impactsList.innerHTML = "";
    if (!impacts) return;

    // Find maximum absolute contribution for scaling
    const maxAbs = Math.max(...impacts.map((i) => Math.abs(i.value)), 7.0);

    impacts.forEach((item) => {
      const row = document.createElement("div");
      row.className = "impact-bar-item";

      const widthPct = Math.min(100, Math.max(8, (Math.abs(item.value) / maxAbs) * 100));
      const valStr = item.value >= 0 && item.type !== "baseline" ? `+${item.value}` : `${item.value}`;

      row.innerHTML = `
        <span class="impact-name" title="${item.feature}">${item.feature}</span>
        <div class="impact-track">
          <div class="impact-fill ${item.type}" style="width: ${widthPct}%;"></div>
        </div>
        <span class="impact-value">${valStr}</span>
      `;
      impactsList.appendChild(row);
    });
  }

  // -------------------------------------------------------------
  // 5. Book Search Feature
  // -------------------------------------------------------------
  let searchTimer = null;
  inputSearch.addEventListener("input", () => {
    clearTimeout(searchTimer);
    searchTimer = setTimeout(() => {
      performSearch(inputSearch.value.trim());
    }, 280);
  });

  async function performSearch(query) {
    booksGrid.innerHTML = `
      <div style="grid-column: 1 / -1; text-align: center; padding: 40px; color: var(--text-secondary);">
        Searching books dataset...
      </div>
    `;

    try {
      const res = await fetch(`/api/books?q=${encodeURIComponent(query)}&limit=16`);
      const data = await res.json();
      renderBooks(data.books);
    } catch (err) {
      console.error("Search failed:", err);
      booksGrid.innerHTML = `<div style="grid-column: 1 / -1; color: var(--danger); text-align: center;">Failed to load books.</div>`;
    }
  }

  function renderBooks(books) {
    booksGrid.innerHTML = "";
    if (!books || books.length === 0) {
      booksGrid.innerHTML = `
        <div style="grid-column: 1 / -1; text-align: center; padding: 40px; color: var(--text-muted);">
          No matching books found in dataset. Try searching "Potter", "Tolkien", "King", or "Novel".
        </div>
      `;
      return;
    }

    books.forEach((b) => {
      const card = document.createElement("article");
      card.className = "book-card";

      // Fallback placeholder cover SVG
      const fallbackImg = `data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="120" height="160" viewBox="0 0 120 160"><rect width="120" height="160" fill="%231e293b"/><text x="50%" y="50%" fill="%2364748b" dominant-baseline="middle" text-anchor="middle" font-size="12" font-family="sans-serif">Book Cover</text></svg>`;
      const imgUrl = b.image_url || fallbackImg;

      card.innerHTML = `
        <div class="book-cover-wrap">
          <img class="book-cover-img" src="${imgUrl}" alt="${escapeHtml(b.title)}" onerror="this.onerror=null; this.src='${fallbackImg}';">
        </div>
        <div class="book-info">
          <h4 title="${escapeHtml(b.title)}">${escapeHtml(b.title)}</h4>
          <p class="book-meta">By <strong>${escapeHtml(b.author || 'Unknown')}</strong> (${b.year || 'N/A'})</p>
          <p class="book-meta" style="font-size: 0.72rem; color: var(--text-muted);">${escapeHtml(b.publisher || '')}</p>
        </div>
        <div class="book-actions">
          <button type="button" class="btn-secondary use-book-btn">Predict for This Book &rarr;</button>
        </div>
      `;

      // Use book action
      card.querySelector(".use-book-btn").addEventListener("click", () => {
        inputTitle.value = b.title;
        const pubYear = parseInt(b.year);
        if (!isNaN(pubYear) && pubYear >= 1850 && pubYear <= 2026) {
          inputPubYear.value = pubYear;
        }
        updateInputBadges();
        triggerPrediction();

        // Switch to Predictor Tab
        document.getElementById("tab-btn-predictor").click();
      });

      booksGrid.appendChild(card);
    });
  }

  function escapeHtml(text) {
    if (!text) return "";
    return text.replace(/[&<>"']/g, (m) => ({
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      '"': "&quot;",
      "'": "&#39;",
    }[m]));
  }

  // -------------------------------------------------------------
  // 6. Diagnostics & Metrics Loader
  // -------------------------------------------------------------
  async function loadMetrics() {
    try {
      const res = await fetch("/api/metrics");
      const data = await res.json();

      if (data.coefficients && coefTbody) {
        coefTbody.innerHTML = "";
        data.coefficients.forEach((c) => {
          const tr = document.createElement("tr");

          // Significance stars
          let stars = "";
          if (c.p_value < 0.001) stars = "***";
          else if (c.p_value < 0.01) stars = "**";
          else if (c.p_value < 0.05) stars = "*";
          else stars = "n.s.";

          const pStr = c.p_value < 0.0001 ? "< 0.0001" : c.p_value.toFixed(4);

          tr.innerHTML = `
            <td><code>${c.feature}</code></td>
            <td><strong>${c.estimate.toFixed(5)}</strong></td>
            <td>${c.std_error.toFixed(5)}</td>
            <td>${c.t_value.toFixed(2)}</td>
            <td>${pStr}</td>
            <td><span class="sig-badge">${stars}</span></td>
          `;
          coefTbody.appendChild(tr);
        });
      }
    } catch (err) {
      console.error("Failed to load metrics:", err);
    }
  }

  // Initial Load
  updateInputBadges();
  triggerPrediction();
});
