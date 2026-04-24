const SUPABASE_URL = "https://YOUR-PROJECT-ID.supabase.co";
const SUPABASE_KEY = "YOUR_PUBLISHABLE_OR_ANON_KEY";

const supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_KEY);

const reviewForm = document.getElementById("reviewForm");
const formMessage = document.getElementById("formMessage");

if (reviewForm) {
  reviewForm.addEventListener("submit", async function (event) {
    event.preventDefault();

    formMessage.textContent = "Submitting...";
    formMessage.style.color = "#136f3a";

    const payload = {
      reviewer_name: document.getElementById("reviewer_name").value.trim() || null,
      pitch_id: Number(document.getElementById("pitch_id").value),
      quality_of_opposition: Number(document.getElementById("quality_of_opposition").value),
      quality_of_pitch: Number(document.getElementById("quality_of_pitch").value),
      price_per_team_per_game: Number(document.getElementById("price_per_team_per_game").value),
      overall_experience: Number(document.getElementById("overall_experience").value)
    };

    const { error } = await supabaseClient
      .from("fct_reviews")
      .insert([payload]);

    if (error) {
      console.error("Supabase insert error:", error);
      formMessage.textContent = `Error: ${error.message}`;
      formMessage.style.color = "#b00020";
      return;
    }

    formMessage.textContent = "Thanks — your review has been saved.";
    formMessage.style.color = "#136f3a";
    reviewForm.reset();
  });
}
