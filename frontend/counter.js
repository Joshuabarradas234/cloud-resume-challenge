/*
 * Visitor counter client.
 *
 * On load, POSTs to the counter API, which atomically increments the count in
 * DynamoDB and returns the new total. The number is then counted up into the
 * telemetry readout in the status bar.
 *
 * If the API is unreachable, the readout falls back to "—" and the page is
 * otherwise unaffected — the résumé never depends on the counter to be usable.
 */

// ── CONFIG ────────────────────────────────────────────────────────────────
// Replace with the invoke URL Terraform outputs (`api_endpoint`), keeping the
// /count path. e.g. "https://abc123.execute-api.eu-west-2.amazonaws.com/count"
const COUNTER_ENDPOINT = "https://s8mvp0cnai.execute-api.eu-west-2.amazonaws.com/count";
// ──────────────────────────────────────────────────────────────────────────

(function () {
  const el = document.getElementById("visit-count");
  if (!el) return;

  function animateTo(target) {
    const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduced || target <= 0) {
      el.textContent = target.toLocaleString();
      return;
    }
    const duration = 700;
    const start = performance.now();
    function frame(now) {
      const p = Math.min((now - start) / duration, 1);
      // ease-out
      const eased = 1 - Math.pow(1 - p, 3);
      el.textContent = Math.round(target * eased).toLocaleString();
      if (p < 1) requestAnimationFrame(frame);
    }
    requestAnimationFrame(frame);
  }

  async function recordVisit() {
    if (COUNTER_ENDPOINT.startsWith("REPLACE_WITH")) {
      // Endpoint not wired yet — leave the placeholder, don't error.
      el.textContent = "—";
      return;
    }
    try {
      const res = await fetch(COUNTER_ENDPOINT, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
      });
      if (!res.ok) throw new Error("HTTP " + res.status);
      const data = await res.json();
      const count = Number(data.count);
      if (Number.isFinite(count)) {
        animateTo(count);
      } else {
        el.textContent = "—";
      }
    } catch (err) {
      console.error("Visitor counter unavailable:", err);
      el.textContent = "—";
    }
  }

  recordVisit();
})();
