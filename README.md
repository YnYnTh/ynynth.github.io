# Personal academic website

Quarto static site, deployed to GitHub Pages by GitHub Actions on every push to
`main`. No paid services, no external asset requests.

## Editing

Each page is a `.qmd` file — Markdown, the same syntax as RMarkdown:

| File              | Page                                     |
| ----------------- | ---------------------------------------- |
| `index.qmd`       | Home / about                             |
| `research.qmd`    | Research interests and spotlights        |
| `publications.qmd`| Intro text only — the list is generated  |
| `publications.bib`| **Source of the publication list**       |
| `teaching.qmd`    | Courses, workshops, evaluation reflection|
| `projects.qmd`    | Dead ends                                |
| `_quarto.yml`     | Site title, navbar, URL                  |
| `styles.scss`     | Palette, fonts, spacing, diagram styles  |

Put PDFs and datasets in `files/`, images in `images/`, then link them as
`files/name.pdf` or `![](images/name.jpg)`.

Preview locally with live reload:

```bash
quarto preview
```

## The publications pipeline

You don't edit the publications list. `_scripts/build_publications.py` runs
before every render (wired up as `pre-render` in `_quarto.yml`) and rebuilds it
from `publications.bib`:

```
publications.bib ──► pandoc + apa.csl ──► _generated/publications.md
                                              │
                              publications.qmd includes it
```

APA 7 formatting is done by Pandoc's citation processor using `apa.csl` — the
same style file Zotero uses, copied from `~/Zotero/styles/apa.csl`. The script
only adds section grouping, reverse-chronological ordering, bolding of your
name, and the link buttons. **Nothing about the APA output is hand-written**,
which is the point: it can't drift from the standard.

It runs in GitHub Actions too, so pushing an updated `.bib` is enough — no need
to render locally first.

`_generated/publications.md` **is committed**, even though it's generated.
Quarto expands `{{< include >}}` while building the project context, which
happens before pre-render scripts run, so the file has to already exist or a
clean checkout fails to build. Committing it also means the last good list
still publishes if the generator ever errors. Expect it to show up as modified
after a local render; that's normal, commit it along with the `.bib`.

### Connect it to Zotero (do this once)

1. In Zotero, put the papers you want listed into one collection
   (e.g. *My publications*)
2. Right-click the collection → **Export Collection**
3. Format **Better BibTeX**, tick **Keep updated**
4. Save as `~/academic-website/publications.bib`, replacing the placeholder file

Better BibTeX now rewrites that file whenever the collection changes. Adding a
paper to your website becomes: add it to Zotero, then `git push`.

### Link buttons come from Zotero's "Extra" field

Better BibTeX exports Zotero's **Extra** field into the bib `note` field, and
the script reads `key: value` pairs out of it. In a Zotero item's Extra box:

```
pdf: files/tang-2026.pdf
data: https://osf.io/abcde
code: https://github.com/tyy/project
```

Recognised keys: `pdf`, `preprint`, `data`, `code`, `materials`, `supplement`,
`slides`, `poster`, `osf`. Anything else in Extra is ignored, so notes to
yourself are harmless.

DOIs are *not* a button — APA 7 requires the DOI inside the reference itself,
so the citation processor already renders it as a link.

One extra key, `section:`, forces an entry into a named section — useful
because Zotero item types don't always map onto CSL types the way you'd guess:

```
section: Conference presentations
```

Section names and order live in `SECTIONS` at the top of the script. Your name
variants for bolding live in `MY_NAMES` just above it — **edit that if you
publish under any other form of your name.**

Publish:

```bash
git add -A && git commit -m "Update publications" && git push
```

The site rebuilds in about a minute. Watch progress on the repo's Actions tab.

## First-time setup

1. Install Quarto: `brew install --cask quarto`
2. Create a **public** GitHub repo named exactly `tyy.github.io`
3. Username `tyy` is already set throughout
4. Push this folder to the repo
5. Repo **Settings → Pages → Source: GitHub Actions**
6. Site goes live at `https://tyy.github.io`

## Adding a custom domain later

1. Buy the domain (Cloudflare Registrar or Porkbun, ~$10/yr, sold at cost)
2. DNS records at the registrar:
   - Four `A` records for the apex domain → `185.199.108.153`,
     `185.199.109.153`, `185.199.110.153`, `185.199.111.153`
   - One `CNAME` for `www` → `tyy.github.io`
3. Repo **Settings → Pages → Custom domain**, enter it, wait for the DNS check,
   then tick **Enforce HTTPS** once the certificate is issued (a few minutes)
4. Update `site-url` in `_quarto.yml`

GitHub then 301-redirects `tyy.github.io` to the new domain, so old links
keep working. Certificates are free and auto-renewing.

## Keeping it accessible from mainland China

The host is rarely the problem — third-party assets are. Google Fonts, Google
Analytics, Google Scholar badges, Dropbox, Google Drive, and `cdn.jsdelivr.net`
are blocked or unreliable there, and each one stalls page load for every visitor
in China. This site is set up to avoid all of them:

- `theme: styles.scss` — plain Bootstrap, no Bootswatch Google Fonts import
- `$web-font-path: ""` in `styles.scss` — belt and braces on the same issue
- `html-math-method: plain` — no MathJax/KaTeX CDN fetch
- `search: false` — Quarto's search widget bundles Algolia autocomplete, which
  carries a `cdn.jsdelivr.net` loader for its optional analytics module. Inert
  unless insights are enabled, but it was the only CDN string in the build, so
  it's gone. **Turning search back on reintroduces it.**
- `apa.csl` committed locally rather than fetched from the CSL repo
- system font stack, including CJK faces
- no analytics, no Scholar badge, no CDN libraries

Verified: loading the built site and watching the network panel shows requests
to the local host and inline `data:` URIs only — no external hosts.

Two things in the *content* still point at blocked services: the Google Scholar
link on the home page, and any Zotero `note:` links to Dropbox or Google Drive.
Those are links a visitor clicks, not assets the page loads, so they don't
break the site — but a reader in China can't follow them. Host files in
`files/` instead.

**Rule of thumb: if you paste in an embed or `<script src="https://...">`,
assume it breaks the site in China until you've verified otherwise.**

Test from Chinese network vantage points after any significant change:
<https://www.itdog.cn/http/> or <https://boce.aliyun.com/>

## Optional: a warm standby

Connect the same repo to Cloudflare Pages (free, build command `quarto render`,
output `_site`). It deploys from the same pushes, so if GitHub Pages has a bad
month you can repoint DNS in minutes.

## Note on location

Keep this folder **outside** OneDrive/Dropbox/iCloud Drive. Sync clients and
git's `.git` directory conflict, and the failure mode is a corrupted repo.
