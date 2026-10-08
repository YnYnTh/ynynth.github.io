/* Home page motion.
 *
 * 1. The card: two lines with a slow, breathing rhythm. Every few seconds
 *    they ease into a new pattern: where the challenge falls, how deep the
 *    response is, how fast each line oscillates, how closely the second line
 *    follows the first, and the second line's color.
 * 2. About: the scattered pieces drift at slightly different speeds as the
 *    page scrolls (wide screens only).
 * 3. Sections fade up as they scroll into view.
 *
 * Visitors who ask for reduced motion get still lines and no fades.
 * Local file, no libraries, nothing fetched from another server.
 */
(function () {
  "use strict";

  var hp = document.getElementById("hp");
  if (!hp) return;
  hp.classList.add("js");
  var reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  /* ----------------------------------------------------------- card ---- */
  var card = hp.querySelector(".ts-card svg");
  if (card) {
    var la = card.querySelector(".ln-a"), lb = card.querySelector(".ln-b"), band = card.querySelector(".band");
    var PATTERNS = [
      { b0: .30, b1: .62, aA: 1.00, aB: 1.00, fA: 1.00, fB: 1.00, lag: .035, col: 0 },
      { b0: .16, b1: .44, aA: 1.30, aB: .80, fA: 1.15, fB: .90, lag: .09, col: 1 },
      { b0: .50, b1: .80, aA: .80, aB: 1.25, fA: .85, fB: 1.10, lag: 0, col: 2 },
      { b0: .24, b1: .52, aA: 1.10, aB: 1.05, fA: 1.30, fB: 1.25, lag: .13, col: 3 },
      { b0: .40, b1: .72, aA: .90, aB: .70, fA: .95, fB: .75, lag: .05, col: 0 },
      { b0: .10, b1: .36, aA: 1.20, aB: 1.15, fA: 1.05, fB: 1.40, lag: .02, col: 1 }
    ];
    var COLORS = ["#437b8e", "#e0851c", "#cc403c", "#576ea5"];
    var V = Object.assign({}, PATTERNS[0]), T = Object.assign({}, PATTERNS[0]), pat = 0;

    var sm = function (a, b, x) { var t = Math.min(1, Math.max(0, (x - a) / (b - a))); return t * t * (3 - 2 * t); };
    var load = function (x) { return sm(V.b0, V.b0 + 0.07, x) * (1 - sm(V.b1, V.b1 + 0.28, x)); };
    var wobble = function (x, t, s) {
      return 0.55 * Math.sin(2 * Math.PI * 1.7 * x + 0.21 * t + s) +
             0.30 * Math.sin(2 * Math.PI * 3.9 * x - 0.13 * t + 2.1 * s) +
             0.15 * Math.sin(2 * Math.PI * 7.3 * x + 0.34 * t + 0.7 * s);
    };

    var waves = function (t) {
      var r = card.getBoundingClientRect(), W = r.width, H = r.height;
      if (!W) return;
      card.setAttribute("viewBox", "0 0 " + W.toFixed(1) + " " + H.toFixed(1));
      for (var k in V) if (k !== "col") V[k] += (T[k] - V[k]) * 0.03;
      band.setAttribute("x", ((V.b0 + 0.035) * W).toFixed(1));
      band.setAttribute("width", ((V.b1 - V.b0) * W).toFixed(1));
      band.setAttribute("height", H.toFixed(1));
      var cA = Math.max(6, W / 34 * V.fA), cB = Math.max(4, W / 56 * V.fB), v = 18;
      var wA = 2 * Math.PI * v / (W / cA), wB = 2 * Math.PI * v / (W / cB);
      var N = Math.round(W / 2), a = "", b = "";
      for (var i = 0; i <= N; i++) {
        var x = i / N, LA = load(x), LB = load(x - V.lag), sh = wobble(x, t, 0), X = (x * W).toFixed(1);
        var ya = H * (0.28 + 0.08 * LA + 0.1 * V.aA * (1 - 0.62 * LA) * Math.sin(2 * Math.PI * cA * x + wA * t) + 0.035 * sh);
        var yb = H * (0.72 + 0.05 * LB + 0.075 * V.aB * (1 - 0.35 * LB) * Math.sin(2 * Math.PI * cB * x + wB * t + 1.3) +
                      0.03 * (0.6 * sh + 0.4 * wobble(x, t, 4.2)));
        a += (i ? "L" : "M") + X + " " + ya.toFixed(1);
        b += (i ? "L" : "M") + X + " " + yb.toFixed(1);
      }
      la.setAttribute("d", a);
      lb.setAttribute("d", b);
    };

    waves(0);
    window.addEventListener("resize", function () { waves(0); });

    if (!reduce) {
      var visible = true, start = null;
      setInterval(function () {
        if (document.hidden || !visible) return;
        pat = (pat + 1) % PATTERNS.length;
        T = Object.assign({}, PATTERNS[pat]);
        lb.style.stroke = COLORS[T.col];
      }, 5000);
      var frame = function (now) {
        if (start === null) start = now;
        if (visible) waves((now - start) / 1000);
        requestAnimationFrame(frame);
      };
      if ("IntersectionObserver" in window) {
        new IntersectionObserver(function (es) { visible = es[0].isIntersecting; }).observe(card);
      }
      requestAnimationFrame(frame);
    }
  }

  /* ------------------------------------------------- About: drift ---- */
  var drifters = [].slice.call(hp.querySelectorAll(".scatter [data-speed]"));
  var ticking = false;
  var parallax = function () {
    ticking = false;
    var mid = window.innerHeight / 2;
    drifters.forEach(function (el) {
      var r = el.getBoundingClientRect();
      var off = (r.top + r.height / 2 - mid) * parseFloat(el.getAttribute("data-speed"));
      el.style.setProperty("--py", Math.max(-60, Math.min(60, off)).toFixed(1) + "px");
    });
  };
  if (!reduce && window.innerWidth > 900 && drifters.length) {
    window.addEventListener("scroll", function () {
      if (!ticking) { ticking = true; requestAnimationFrame(parallax); }
    }, { passive: true });
    parallax();
  }

  /* --------------------------------------------- fade up on scroll ---- */
  var io = ("IntersectionObserver" in window && !reduce) ? new IntersectionObserver(function (es) {
    es.forEach(function (e) {
      if (e.isIntersecting) { e.target.classList.add("in"); io.unobserve(e.target); }
    });
  }, { threshold: 0.15 }) : null;
  hp.querySelectorAll("[data-reveal]").forEach(function (el) {
    if (io) io.observe(el); else el.classList.add("in");
  });
})();
