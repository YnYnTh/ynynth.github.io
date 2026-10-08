/* Interactive research figures (research.qmd).
 *
 * - Pointing at, focusing, or tapping any element with data-explain shows its
 *   text in the figure's explanation box.
 * - Buttons with data-group / data-state set data-<group> on the figure; the
 *   stylesheet shows the matching group.
 * - A slider moves a dot along a curve (coping flexibility).
 * - On the RSA panel, moving across the plot reads the predicted value off
 *   the curve for the strategy shown.
 * - On the family network, pointing at a circle keeps only its own lines.
 *
 * Local file, no libraries, nothing fetched from another server.
 */
(function () {
  "use strict";

  document.querySelectorAll(".ifig").forEach(function (fig) {
    var out = fig.querySelector(".ifig-explain");
    if (!out) return;
    var current = out.innerHTML;
    var say = function (html) { out.innerHTML = html; };
    var clearHot = function () {
      fig.querySelectorAll(".is-hot").forEach(function (e) { e.classList.remove("is-hot"); });
    };

    fig.querySelectorAll("[data-explain]:not(button)").forEach(function (el) {
      if (!el.hasAttribute("tabindex")) el.setAttribute("tabindex", "0");
      var show = function () { clearHot(); el.classList.add("is-hot"); say(el.getAttribute("data-explain")); };
      el.addEventListener("mouseenter", show);
      el.addEventListener("focus", show);
      el.addEventListener("click", function () { show(); current = el.getAttribute("data-explain"); });
    });
    fig.addEventListener("mouseleave", function () { clearHot(); say(current); });

    fig.querySelectorAll("button[data-group]").forEach(function (btn) {
      btn.addEventListener("click", function () {
        var group = btn.getAttribute("data-group");
        fig.setAttribute("data-" + group, btn.getAttribute("data-state"));
        fig.querySelectorAll('button[data-group="' + group + '"]').forEach(function (b) {
          b.setAttribute("aria-pressed", b === btn ? "true" : "false");
        });
        current = btn.getAttribute("data-explain");
        say(current);
      });
    });

    /* Slider: the dot follows the curve at the slider's horizontal position. */
    var range = fig.querySelector(".ifig-range");
    if (range) {
      var curve = fig.querySelector(".u-curve"), dot = fig.querySelector(".u-dot");
      var texts = [range.getAttribute("data-low"), range.getAttribute("data-mid"), range.getAttribute("data-high")];
      var pointAtX = function (x) {
        var len = curve.getTotalLength(), lo = 0, hi = len, p = curve.getPointAtLength(0);
        for (var i = 0; i < 24; i++) {
          var mid = (lo + hi) / 2;
          p = curve.getPointAtLength(mid);
          if (p.x < x) lo = mid; else hi = mid;
        }
        return p;
      };
      var move = function (announce) {
        var v = Number(range.value) / 100;
        var a = curve.getPointAtLength(0), b = curve.getPointAtLength(curve.getTotalLength());
        var p = pointAtX(a.x + v * (b.x - a.x));
        dot.setAttribute("cx", p.x.toFixed(1));
        dot.setAttribute("cy", p.y.toFixed(1));
        if (announce) {
          current = texts[v < 0.37 ? 0 : (v > 0.61 ? 2 : 1)];
          say(current);
        }
      };
      range.addEventListener("input", function () { move(true); });
      move(false);
    }

    /* RSA panel: read the predicted value at the pointer's second. */
    fig.querySelectorAll("svg[data-scrub]").forEach(function (svg) {
      var dot = svg.querySelector(".scrub-dot"), txt = svg.querySelector(".scrub-txt");
      var X0 = +svg.getAttribute("data-x0"), X1 = +svg.getAttribute("data-x1");
      var Y0 = +svg.getAttribute("data-y0"), Y1 = +svg.getAttribute("data-y1");
      var hide = function () { dot.classList.remove("on"); txt.textContent = ""; };
      svg.addEventListener("pointermove", function (ev) {
        var m = svg.getScreenCTM();
        if (!m) return;
        var x = (ev.clientX - m.e) / m.a;
        if (x < X0 || x > X1) { hide(); return; }
        var c = (svg.getAttribute("data-coef-" + fig.getAttribute("data-strat")) || "").split(",").map(Number);
        if (c.length < 5) return;
        var t = (x - X0) / (X1 - X0) * 20 - 10, u = t + 10;
        var v = c[0] + c[1] * u + c[2] * u * u;
        var y = Y1 - (v - c[3]) / (c[4] - c[3]) * (Y1 - Y0);
        dot.setAttribute("cx", x.toFixed(1));
        dot.setAttribute("cy", y.toFixed(1));
        dot.classList.add("on");
        var s = Math.round(t);
        txt.textContent = (s === 0 ? "start" : (s < 0 ? "−" + (-s) + " s" : "+" + s + " s")) + " · RSA " + v.toFixed(2);
      });
      svg.addEventListener("pointerleave", hide);
    });

    /* Family network: pointing at a circle keeps its own lines and neighbors. */
    var net = fig.querySelector("svg.net");
    if (net) {
      var edges = [].slice.call(net.querySelectorAll(".e"));
      var focusOn = function (id) {
        net.classList.add("hov");
        var keep = {};
        keep[id] = true;
        edges.forEach(function (e) {
          var a = e.getAttribute("data-a"), b = e.getAttribute("data-b"), on = a === id || b === id;
          e.classList.toggle("on", on);
          if (on) { keep[a] = true; keep[b] = true; }
        });
        net.querySelectorAll(".nodes .nd, .labels .nl").forEach(function (n) {
          n.classList.toggle("on", !!keep[n.getAttribute("data-id")]);
        });
      };
      var clear = function () {
        net.classList.remove("hov");
        net.querySelectorAll(".on").forEach(function (n) { n.classList.remove("on"); });
      };
      net.querySelectorAll(".nodes .nd").forEach(function (nd) {
        var id = nd.getAttribute("data-id");
        nd.addEventListener("mouseenter", function () { focusOn(id); });
        nd.addEventListener("focus", function () { focusOn(id); });
        nd.addEventListener("mouseleave", clear);
        nd.addEventListener("blur", clear);
      });
    }
  });
})();
