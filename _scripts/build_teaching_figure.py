#!/usr/bin/env python3
"""Build the Evaluations figure on teaching.qmd: the HDF 315L instructor
evaluation on top and the teaching-assistant appointments below, in one card.

Writes _partials/teaching/fig-evaluations.md, which teaching.qmd includes.

Numbers come from the UT course-evaluation reports (checked 2026-10-08): students = "Courses Audience", responses = "Responses
Received", rating = mean of the seven teaching-assistant items. Praise and
requests summarize the anonymous comments in those reports.

Run by hand after changing the data:
    python3 _scripts/build_teaching_figure.py
"""
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "_partials", "teaching")

# term: year + 0.25 for spring, + 0.75 for fall
TA = [
    dict(code="HDF 313", name="Child Development", term="Fall 2022", t=2022.75, n=216, resp=86, rating=3.92, kind="lecture",
         praised="comments on lab assignments; quick, patient answers",
         asked="a more visible presence in lecture; grading that matched the professor’s"),
    dict(code="HDF 313", name="Child Development", term="Spring 2024", t=2024.25, n=96, resp=64, rating=3.95, kind="lecture",
         praised="explaining what went wrong and how to improve; quick replies",
         asked="clearer, more consistent grading"),
    dict(code="HDF 315L", name="Research Methods", term="Spring 2024", t=2024.25, n=24, resp=22, rating=4.13, kind="methods",
         praised="detailed comments when grading; fast replies",
         asked="more presence during class; less harsh grading"),
    dict(code="HDF 313", name="Child Development", term="Fall 2024", t=2024.75, n=111, resp=51, rating=4.10, kind="lecture",
         praised="staying after class to answer questions; feedback that helped on later work",
         asked="more engagement in class; example lab assignments"),
    dict(code="NTR 306", name="Fundamentals of Nutrition (online)", term="Spring 2025", t=2025.25, n=2059, resp=61, rating=4.43, kind="online",
         praised="feedback on assignments; quick email replies and reminders",
         asked="mostly nothing"),
    dict(code="HDF 380K.2", name="Foundational Statistics", term="Spring 2025", t=2025.25, n=8, resp=7, rating=5.00, kind="stats",
         praised="clear statistics explanations; R help; detailed homework feedback",
         asked="nothing"),
    dict(code="HDF 380K.2", name="Foundational Statistics", term="Spring 2026", t=2026.25, n=6, resp=6, rating=4.86, kind="stats", dx=-8,
         praised="R expertise; detailed feedback; help with their own research",
         asked="no changes (one student found the grading harsh)"),
    dict(code="HDF 380K.4", name="Structural Equation Modeling", term="Spring 2026", t=2026.25, n=14, resp=8, rating=4.90, kind="stats", dx=8,
         praised="generous with time; prompt replies; clear explanations",
         asked="nothing"),
]
IOR = [
    ("Fostered an inclusive environment", "The instructor fostered an inclusive learning environment.", 4.71),
    ("Objectives and expectations clear", "The instructor clearly explained the course objectives and expectations.", 4.57),
    ("Overall, this instructor", "Overall, this instructor was …", 4.43),
    ("Gained deeper understanding", "I gained a deeper understanding of the subject matter.", 4.43),
    ("Course was well organized", "The course was well organized.", 4.43),
    ("Checked for understanding", "The instructor checked for student understanding.", 4.43),
    ("Concepts effectively explained", "The instructor effectively explained the concepts and subject matter.", 4.29),
    ("Techniques kept me engaged", "The instructional techniques kept me engaged in learning.", 4.14),
]
FILL = {"lecture": "#b3c8e0", "methods": "#5f9fb4", "online": "#8baf7b", "stats": "#fc9833"}
KIND = {"lecture": "undergraduate lecture", "methods": "undergraduate methods", "online": "online course", "stats": "graduate statistics"}

X0, X1, Y0, Y1 = 70, 604, 44, 236
T0, T1 = 2022.5, 2026.5
R0, R1 = 3.6, 5.1
CAP = 30


def xp(t):
    return X0 + (t - T0) / (T1 - T0) * (X1 - X0)


def yp(r):
    return Y1 - (r - R0) / (R1 - R0) * (Y1 - Y0)


def radius(n):
    return min(CAP, 3 + 0.95 * math.sqrt(n))


def ta_svg():
    parts = []
    for v in [4.0, 4.5, 5.0]:
        y = yp(v)
        parts.append(f'<line class="grid" x1="{X0}" y1="{y:.1f}" x2="{X1}" y2="{y:.1f}"/>'
                     f'<text x="{X0 - 8}" y="{y + 3.5:.1f}" text-anchor="end">{v:.1f}</text>')
    parts.append(f'<line class="ax" x1="{X0}" y1="{Y1}" x2="{X1}" y2="{Y1}"/>')
    for yr in [2023, 2024, 2025, 2026]:
        x = xp(yr)
        parts.append(f'<line class="ax" x1="{x:.1f}" y1="{Y1}" x2="{x:.1f}" y2="{Y1 + 5}"/>'
                     f'<text x="{x:.1f}" y="{Y1 + 18}" text-anchor="middle">{yr}</text>')
    parts.append(f'<text class="ax-t" x="{X0}" y="{Y0 - 30}">TA rating, mean of seven items (1 to 5)</text>')

    bubbles, labels = [], []
    for d in sorted(TA, key=lambda d: -d["n"]):
        x = xp(d["t"]) + d.get("dx", 0)
        y = yp(d["rating"])
        r = radius(d["n"])
        capped = r >= CAP
        n = f'{d["n"]:,}'
        exp = (f'<b>{d["code"]}, {d["name"]}</b> · {d["term"]} · {KIND[d["kind"]]}<br>'
               f'{n} students, {d["resp"]} responded · mean rating {d["rating"]:.2f}<br>'
               f'<b>Praised:</b> {d["praised"]}.<br><b>Asked for:</b> {d["asked"]}.')
        cls = "ta" + (" capped" if capped else "")
        bubbles.append(f'<g class="{cls}" tabindex="0" data-explain="{exp}">'
                       f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.1f}" style="fill:{FILL[d["kind"]]}"/></g>')
        # label placement
        if d["kind"] == "stats":
            left = d["code"] == "HDF 380K.2" and d["term"] == "Spring 2026"
            lx = x - r - 4 if left else x + r + 4
            labels.append(f'<text class="ta-l" x="{lx:.1f}" y="{y + 3.5:.1f}" text-anchor="{"end" if left else "start"}">{d["code"].replace("HDF ", "")}</text>')
        elif d["kind"] == "online":
            labels.append(f'<text class="ta-l" x="{x + r + 6:.1f}" y="{y + 1:.1f}">NTR 306 · {n} online</text>')
            labels.append(f'<text class="ta-note" x="{x + r + 6:.1f}" y="{y + 13:.1f}">circle not to scale</text>')
        elif d["code"] == "HDF 315L":
            labels.append(f'<text class="ta-l" x="{x - r - 5:.1f}" y="{y + 3.5:.1f}" text-anchor="end">315L</text>')
        else:
            labels.append(f'<text class="ta-l" x="{x:.1f}" y="{y + r + 13:.1f}" text-anchor="middle">313</text>')

    key = []
    for kx, k in zip([X0 + 5, X0 + 139, X0 + 273, X0 + 365], ["lecture", "methods", "online", "stats"]):
        key.append(f'<circle cx="{kx}" cy="{Y0 - 13}" r="5" style="fill:{FILL[k]}"/>'
                   f'<text x="{kx + 9}" y="{Y0 - 9.5}">{KIND[k]}</text>')

    svg = f'''
<svg viewBox="0 0 640 270" role="img" aria-label="Teaching assistant appointments from 2022 to 2026: circles sized by class size and placed by mean rating. Ratings rise from about 3.9 in large undergraduate lectures to 4.9 to 5.0 in graduate statistics.">
  {"".join(parts)}
  <g class="ta-key">{"".join(key)}</g>
  <g class="tas">{"".join(bubbles)}</g>
  <g class="ta-labels">{"".join(labels)}</g>
  <text class="ta-note" x="{X1}" y="{Y1 + 30}" text-anchor="end">circle area = number of students</text>
</svg>'''

    return svg


def ior_svg():
    L, R, top, row = 250, 610, 24, 27

    def xs(v):
        return L + (v - 1) / 4 * (R - L)

    parts = []
    for v in [1, 2, 3, 4, 5]:
        parts.append(f'<line class="grid" x1="{xs(v):.1f}" y1="{top - 8}" x2="{xs(v):.1f}" y2="{top + row * len(IOR) - 10}"/>'
                     f'<text x="{xs(v):.1f}" y="{top + row * len(IOR) + 6}" text-anchor="middle">{v}</text>')
    for i, (short, full, m) in enumerate(IOR):
        y = top + i * row
        parts.append(f'<g class="ior" tabindex="0" data-explain="<b>{full}</b> Mean {m:.2f} on a 1 to 5 scale (7 of 9 students).">'
                     f'<rect class="ior-hit" x="0" y="{y - 12}" width="{R + 30}" height="{row}"/>'
                     f'<text class="ior-l" x="{L - 14}" y="{y + 4}" text-anchor="end">{short}</text>'
                     f'<line class="ior-track" x1="{L}" y1="{y}" x2="{xs(m):.1f}" y2="{y}"/>'
                     f'<circle class="ior-dot" cx="{xs(m):.1f}" cy="{y}" r="6"/>'
                     f'<text class="ior-v" x="{xs(m) + 11:.1f}" y="{y + 4}">{m:.2f}</text></g>')
    h = top + row * len(IOR) + 24
    parts.append(f'<text class="ta-note" x="{(L + R) / 2:.0f}" y="{h - 2}" text-anchor="middle">mean rating · full 1 to 5 scale · n = 7</text>')
    return (f'<svg viewBox="0 0 640 {h + 4}" role="img" aria-label="Course evaluation item means for HDF 315L, Fall 2025, between 4.14 and 4.71 on a one-to-five scale.">'
            + "".join(parts) + "</svg>")


def build():
    html = f"""
<figure class="ifig ifig-eval">
  <p class="ifig-sub">HDF 315L, Research Methods, Fall 2025, my first course as instructor of record. 7 of 9 students responded.</p>
  {ior_svg()}
  <p class="ifig-sub ifig-sub-2">An overview of TA experiences</p>
  {ta_svg()}
  <p class="ifig-explain" aria-live="polite">Point at an item or a circle to see the details. Each circle is one teaching assistant appointment with a student evaluation: its size is the number of students, its height the mean rating.</p>
</figure>"""
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "fig-evaluations.md"), "w", encoding="utf-8") as fh:
        fh.write("<!-- Generated by _scripts/build_teaching_figure.py; edit that script, not this file. -->\n")
        fh.write("```{=html}\n" + html.strip() + "\n```\n")


if __name__ == "__main__":
    build()
    print("wrote _partials/teaching/fig-evaluations.md")
