/*
 * Scroll-reveal + diagram draw-in.
 * Progressive enhancement: if JS or IntersectionObserver is unavailable, or the
 * visitor prefers reduced motion, everything is shown in its final state and
 * nothing here runs. No layout depends on it.
 */
(function () {
  var reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  var els = document.querySelectorAll(".reveal, .diagram");
  if (reduce || !("IntersectionObserver" in window) || !els.length) {
    els.forEach(function (el) { el.classList.add("is-in"); });
    return;
  }
  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (e.isIntersecting) {
        e.target.classList.add("is-in");
        io.unobserve(e.target);
      }
    });
  }, { threshold: 0.14, rootMargin: "0px 0px -8% 0px" });
  els.forEach(function (el) { io.observe(el); });
})();
