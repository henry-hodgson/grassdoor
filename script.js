const SUPABASE_URL = "https://bmphqborkcfzwfoiareu.supabase.co";
const SUPABASE_KEY = "sb_publishable_ISG0nODF3NbXTLmtFRsp4A_tEkdBYb8";
const supabaseClient = window.supabase
  ? window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY)
  : null;

// Mirrors the exact public.dim_pitches schema. Used only if Supabase cannot be read.
const FALLBACK_PITCHES = [
  { id: 1, name: "Powerleague Shoreditch", area: "East London", nearest_station: "Old Street", game_format: "5-a-side", length: 40, width: 30, walls: true, overhead_net: true, men: true, women: true, under_18: true, showers: true },
  { id: 2, name: "Goals Eltham", area: "South London", nearest_station: "Mottingham", game_format: "5-a-side", length: 40, width: 30, walls: true, overhead_net: true, men: true, women: true, under_18: true, showers: true },
  { id: 3, name: "Westway Sports Centre", area: "West London", nearest_station: "Latimer Road", game_format: "5-a-side", length: 40, width: 30, walls: true, overhead_net: false, men: true, women: true, under_18: true, showers: true },
  { id: 4, name: "Goals Beckton", area: "East London", nearest_station: "Gallions Reach", game_format: "5-a-side", length: 40, width: 30, walls: true, overhead_net: true, men: true, women: true, under_18: true, showers: true },
  { id: 5, name: "Market Road Football Pitches", area: "North London", nearest_station: "Caledonian Road", game_format: "7-a-side", length: 60, width: 40, walls: false, overhead_net: false, men: true, women: true, under_18: true, showers: true },
  { id: 6, name: "Mile End Park Leisure Centre", area: "East London", nearest_station: "Mile End", game_format: "7-a-side", length: 60, width: 40, walls: false, overhead_net: false, men: true, women: true, under_18: true, showers: true },
  { id: 7, name: "Ferndale Community Sports Centre", area: "South London", nearest_station: "Brixton", game_format: "5-a-side", length: 40, width: 30, walls: false, overhead_net: false, men: true, women: true, under_18: true, showers: true },
  { id: 8, name: "Paddington Recreation Ground", area: "West London", nearest_station: "Maida Vale", game_format: "11-a-side", length: 100, width: 64, walls: false, overhead_net: false, men: true, women: true, under_18: true, showers: true }
];

let cachedPitches = null;
let cachedReviews = null;
let pitchDataSource = "fallback";

const escapeHtml = (value) => String(value ?? "")
  .replaceAll("&", "&amp;")
  .replaceAll("<", "&lt;")
  .replaceAll(">", "&gt;")
  .replaceAll('"', "&quot;")
  .replaceAll("'", "&#039;");

const numberOrNull = (value) => {
  if (value === null || value === undefined || value === "") return null;
  const n = Number(value);
  return Number.isFinite(n) ? n : null;
};

function normalizePitch(row) {
  return {
    id: numberOrNull(row.id),
    created_at: row.created_at ?? null,
    name: row.name || "Unnamed pitch",
    area: row.area || "London",
    nearest_station: row.nearest_station || "",
    game_format: row.game_format || "Football",
    length: numberOrNull(row.length),
    width: numberOrNull(row.width),
    walls: row.walls === true,
    overhead_net: row.overhead_net === true,
    men: row.men === true,
    women: row.women === true,
    under_18: row.under_18 === true,
    showers: row.showers === true
  };
}

async function loadPitches() {
  if (cachedPitches) return cachedPitches;
  if (!supabaseClient) return (cachedPitches = FALLBACK_PITCHES.map(normalizePitch));

  try {
    const { data, error } = await supabaseClient
      .from("dim_pitches")
      .select("id, created_at, name, area, nearest_station, game_format, length, width, walls, overhead_net, men, women, under_18, showers")
      .order("name", { ascending: true });

    if (error) throw error;
    if (Array.isArray(data) && data.length) {
      pitchDataSource = "dim_pitches";
      cachedPitches = data.map(normalizePitch);
      return cachedPitches;
    }
  } catch (error) {
    console.warn("Could not load dim_pitches; using fallback data.", error);
  }

  cachedPitches = FALLBACK_PITCHES.map(normalizePitch);
  return cachedPitches;
}

async function loadReviews() {
  if (cachedReviews) return cachedReviews;
  if (!supabaseClient) return (cachedReviews = []);

  try {
    const { data, error } = await supabaseClient.from("fct_reviews").select("*");
    if (error) throw error;
    cachedReviews = Array.isArray(data) ? data : [];
  } catch (error) {
    console.warn("Could not load reviews.", error);
    cachedReviews = [];
  }
  return cachedReviews;
}

const average = (values) => {
  const clean = values.map(Number).filter(Number.isFinite);
  return clean.length ? clean.reduce((a, b) => a + b, 0) / clean.length : null;
};

function getPitchStats(id, reviews) {
  const matching = reviews.filter((review) => Number(review.pitch_id) === Number(id));
  return {
    count: matching.length,
    overall: average(matching.map((r) => r.overall_experience)),
    pitchQuality: average(matching.map((r) => r.quality_of_pitch)),
    opposition: average(matching.map((r) => r.quality_of_opposition)),
    price: average(matching.map((r) => r.price_per_team_per_game)),
    reviews: matching
  };
}

const formatScore = (value) => Number.isFinite(value) ? value.toFixed(1) : "New";
const formatPrice = (value) => Number.isFinite(value) ? `£${value.toFixed(value % 1 === 0 ? 0 : 2)}` : "Not rated";
const formatDimensions = (pitch) => pitch.length && pitch.width ? `${pitch.length} × ${pitch.width} m` : "Dimensions not listed";

function featureLabels(pitch) {
  const labels = [];
  if (pitch.walls) labels.push("Walls");
  if (pitch.overhead_net) labels.push("Overhead net");
  if (pitch.showers) labels.push("Showers");
  return labels;
}

function accessLabels(pitch) {
  const labels = [];
  if (pitch.men) labels.push("Men");
  if (pitch.women) labels.push("Women");
  if (pitch.under_18) labels.push("Under 18");
  return labels;
}

function pitchCardHtml(pitch, stats) {
  const rating = Number.isFinite(stats.overall) ? `★ ${stats.overall.toFixed(1)}` : "New";
  const features = featureLabels(pitch);
  const secondary = [pitch.nearest_station, formatDimensions(pitch)].filter(Boolean).join(" · ");

  return `
    <article class="pitch-card">
      <a class="pitch-card-link" href="pitch.html?id=${encodeURIComponent(pitch.id)}">
        <div class="pitch-visual"><span>${escapeHtml(pitch.game_format)}</span></div>
        <div class="pitch-card-body">
          <div class="pitch-card-top">
            <span class="tag">${escapeHtml(pitch.area)}</span>
            <span class="rating">${rating}</span>
          </div>
          <h3>${escapeHtml(pitch.name)}</h3>
          <p class="pitch-meta">${escapeHtml(secondary || "London football pitch")}</p>
          ${features.length ? `<p class="pitch-meta">${escapeHtml(features.join(" · "))}</p>` : ""}
          <div class="pitch-card-bottom">
            <span>${escapeHtml(formatPrice(stats.price))} avg/team</span>
            <span>${stats.count} review${stats.count === 1 ? "" : "s"} →</span>
          </div>
        </div>
      </a>
    </article>`;
}

async function initHome() {
  const el = document.getElementById("featuredPitches");
  if (!el) return;
  const [pitches, reviews] = await Promise.all([loadPitches(), loadReviews()]);
  el.innerHTML = pitches
    .map((pitch) => ({ pitch, stats: getPitchStats(pitch.id, reviews) }))
    .sort((a, b) => (b.stats.overall ?? 0) - (a.stats.overall ?? 0))
    .slice(0, 3)
    .map(({ pitch, stats }) => pitchCardHtml(pitch, stats))
    .join("");
}

function populateSelect(select, values, label) {
  select.innerHTML = `<option value="">${label}</option>` +
    [...new Set(values.filter(Boolean))]
      .sort()
      .map((value) => `<option value="${escapeHtml(value)}">${escapeHtml(value)}</option>`)
      .join("");
}

async function initPitches() {
  const grid = document.getElementById("pitchGrid");
  if (!grid) return;

  const [pitches, reviews] = await Promise.all([loadPitches(), loadReviews()]);
  const search = document.getElementById("searchInput");
  const area = document.getElementById("areaFilter");
  const format = document.getElementById("formatFilter");
  const facility = document.getElementById("facilityFilter");
  const access = document.getElementById("accessFilter");
  const count = document.getElementById("resultCount");
  const empty = document.getElementById("emptyState");
  const note = document.getElementById("dataSourceNote");

  populateSelect(area, pitches.map((p) => p.area), "All areas");
  populateSelect(format, pitches.map((p) => p.game_format), "All formats");

  if (note) {
    note.textContent = pitchDataSource === "dim_pitches"
      ? "Live pitch data from Supabase."
      : "Showing fallback pitches because Supabase pitch data is not currently readable.";
  }

  function render() {
    const q = search.value.trim().toLowerCase();
    const filtered = pitches.filter((pitch) => {
      const haystack = [pitch.name, pitch.area, pitch.nearest_station, pitch.game_format].join(" ").toLowerCase();
      return haystack.includes(q)
        && (!area.value || pitch.area === area.value)
        && (!format.value || pitch.game_format === format.value)
        && (!facility.value || pitch[facility.value] === true)
        && (!access.value || pitch[access.value] === true);
    });

    count.textContent = `${filtered.length} pitch${filtered.length === 1 ? "" : "es"}`;
    grid.innerHTML = filtered.map((p) => pitchCardHtml(p, getPitchStats(p.id, reviews))).join("");
    empty.classList.toggle("hidden", filtered.length !== 0);
  }

  [search, area, format, facility, access].forEach((element) => {
    element.addEventListener(element.tagName === "INPUT" ? "input" : "change", render);
  });

  document.getElementById("clearFilters").addEventListener("click", () => {
    search.value = "";
    area.value = "";
    format.value = "";
    facility.value = "";
    access.value = "";
    render();
  });

  render();
}

function booleanDetail(label, value) {
  return `<div><dt>${escapeHtml(label)}</dt><dd>${value ? "Yes" : "No"}</dd></div>`;
}

async function initPitchDetail() {
  const root = document.getElementById("pitchDetail");
  if (!root) return;

  const id = Number(new URLSearchParams(location.search).get("id"));
  const [pitches, reviews] = await Promise.all([loadPitches(), loadReviews()]);
  const pitch = pitches.find((p) => Number(p.id) === id);

  if (!pitch) {
    root.innerHTML = '<div class="empty-state"><h1>Pitch not found.</h1><a class="button" href="pitches.html">Back to pitches</a></div>';
    return;
  }

  const stats = getPitchStats(pitch.id, reviews);
  const facilities = featureLabels(pitch);
  const access = accessLabels(pitch);
  document.title = `${pitch.name} reviews | Grassdoor`;

  const reviewRows = stats.reviews.length
    ? stats.reviews.map((review) => `
      <article class="review-card">
        <div class="review-card-head">
          <div>
            <strong>${escapeHtml(review.reviewer_name || "Anonymous player")}</strong>
            <p class="muted">Player review</p>
          </div>
          <span class="rating">★ ${Number(review.overall_experience).toFixed(1)}</span>
        </div>
        <div class="review-metrics">
          <span>Pitch <strong>${escapeHtml(review.quality_of_pitch)}/5</strong></span>
          <span>Opposition <strong>${escapeHtml(review.quality_of_opposition)}/5</strong></span>
          <span>Paid <strong>£${Number(review.price_per_team_per_game).toFixed(2)}</strong></span>
        </div>
      </article>`).join("")
    : '<div class="empty-state compact"><h3>No reviews yet.</h3><p>Be the first player to rate this pitch.</p></div>';

  root.innerHTML = `
    <a href="pitches.html" class="text-link back-link">← Back to pitches</a>
    <section class="pitch-detail-hero">
      <div>
        <div class="pitch-card-top detail-tags">
          <span class="tag">${escapeHtml(pitch.area)}</span>
          <span class="tag tag-neutral">${escapeHtml(pitch.game_format)}</span>
        </div>
        <h1>${escapeHtml(pitch.name)}</h1>
        <p class="lead">${escapeHtml(pitch.nearest_station ? `Nearest station: ${pitch.nearest_station}` : "London football pitch")}</p>
        <div class="button-row"><a class="button" href="review.html?pitch=${encodeURIComponent(pitch.id)}">Write a review</a></div>
      </div>
      <div class="rating-panel">
        <div class="rating-main"><span>${formatScore(stats.overall)}</span><small>${stats.count ? `${stats.count} review${stats.count === 1 ? "" : "s"}` : "No reviews yet"}</small></div>
        <div class="rating-row"><span>Pitch quality</span><strong>${formatScore(stats.pitchQuality)}</strong></div>
        <div class="rating-row"><span>Opposition</span><strong>${formatScore(stats.opposition)}</strong></div>
        <div class="rating-row"><span>Avg. team price</span><strong>${formatPrice(stats.price)}</strong></div>
      </div>
    </section>

    <section class="detail-grid schema-detail-grid">
      <div class="card detail-card">
        <p class="eyebrow">Pitch details</p>
        <dl class="detail-list">
          <div><dt>Format</dt><dd>${escapeHtml(pitch.game_format)}</dd></div>
          <div><dt>Dimensions</dt><dd>${escapeHtml(formatDimensions(pitch))}</dd></div>
          <div><dt>Area</dt><dd>${escapeHtml(pitch.area)}</dd></div>
          <div><dt>Nearest station</dt><dd>${escapeHtml(pitch.nearest_station || "Not listed")}</dd></div>
          ${booleanDetail("Walls", pitch.walls)}
          ${booleanDetail("Overhead net", pitch.overhead_net)}
          ${booleanDetail("Showers", pitch.showers)}
        </dl>
      </div>
      <div class="card detail-card">
        <p class="eyebrow">Suitable for</p>
        <div class="facility-list">
          ${access.length ? access.map((item) => `<span class="facility-chip">${escapeHtml(item)}</span>`).join("") : '<span class="muted">Eligibility not listed.</span>'}
        </div>
        <p class="eyebrow detail-subheading">Facilities</p>
        <div class="facility-list">
          ${facilities.length ? facilities.map((item) => `<span class="facility-chip">${escapeHtml(item)}</span>`).join("") : '<span class="muted">No facilities flagged in the database.</span>'}
        </div>
      </div>
    </section>

    <section class="reviews-section">
      <div class="section-heading split-heading">
        <div><p class="eyebrow">Player feedback</p><h2>Reviews</h2></div>
        <a href="review.html?pitch=${encodeURIComponent(pitch.id)}" class="text-link">Add yours →</a>
      </div>
      <div class="review-list">${reviewRows}</div>
    </section>`;
}

async function initReviewForm() {
  const form = document.getElementById("reviewForm");
  if (!form) return;

  const message = document.getElementById("formMessage");
  const select = document.getElementById("pitch_id");
  const pitches = await loadPitches();
  const requested = new URLSearchParams(location.search).get("pitch");

  select.innerHTML = '<option value="">Choose a pitch</option>' + pitches
    .slice()
    .sort((a, b) => a.name.localeCompare(b.name))
    .map((pitch) => `<option value="${escapeHtml(pitch.id)}">${escapeHtml(pitch.name)} — ${escapeHtml(pitch.area)}</option>`)
    .join("");

  if (requested && pitches.some((pitch) => String(pitch.id) === requested)) select.value = requested;

  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    if (!supabaseClient) {
      message.textContent = "Reviews are temporarily unavailable.";
      message.className = "form-message error";
      return;
    }

    message.textContent = "Submitting your review…";
    message.className = "form-message";

    const payload = {
      reviewer_name: document.getElementById("reviewer_name").value.trim() || null,
      pitch_id: Number(select.value),
      quality_of_opposition: Number(document.getElementById("quality_of_opposition").value),
      quality_of_pitch: Number(document.getElementById("quality_of_pitch").value),
      price_per_team_per_game: Number(document.getElementById("price_per_team_per_game").value),
      overall_experience: Number(document.getElementById("overall_experience").value)
    };

    const { error } = await supabaseClient.from("fct_reviews").insert([payload]);
    if (error) {
      console.error("Supabase insert error:", error);
      message.textContent = `Could not save review: ${error.message}`;
      message.className = "form-message error";
      return;
    }

    const reviewedPitch = payload.pitch_id;
    cachedReviews = null;
    form.reset();
    select.value = String(reviewedPitch);
    message.textContent = "Thanks — your review has been saved.";
    message.className = "form-message success";
  });
}

initHome();
initPitches();
initPitchDetail();
initReviewForm();
