# Personal academic website

Quarto static site, deployed to GitHub Pages by GitHub Actions on every push to
`main`. No paid services, no external asset requests.

## Editing

Each page is a `.qmd` file — Markdown, the same syntax as RMarkdown:

| File              | Page                                     |
| ----------------- | ---------------------------------------- |
| `index.qmd`       | Home / about                             |
| `research.qmd`    | Research interests and spotlights        |
| `publications.qmd`| Publications, talks, theses              |
| `outreach.qmd`    | Workshops, teaching materials, guides    |
| `projects.qmd`    | Projects and dead ends                   |
| `_quarto.yml`     | Site title, navbar, URL                  |
| `styles.scss`     | Fonts, colours, spacing                  |

Put PDFs and datasets in `files/`, images in `images/`, then link them as
`files/name.pdf` or `![](images/name.jpg)`.

Preview locally with live reload:

```bash
quarto preview
```

Publish:

```bash
git add -A && git commit -m "Update publications" && git push
```

The site rebuilds in about a minute. Watch progress on the repo's Actions tab.

## First-time setup

1. Install Quarto: `brew install --cask quarto`
2. Create a **public** GitHub repo named exactly `USERNAME.github.io`
3. Replace `USERNAME` in `_quarto.yml`, `index.qmd`, `research.qmd`
4. Push this folder to the repo
5. Repo **Settings → Pages → Source: GitHub Actions**
6. Site goes live at `https://USERNAME.github.io`

## Adding a custom domain later

1. Buy the domain (Cloudflare Registrar or Porkbun, ~$10/yr, sold at cost)
2. DNS records at the registrar:
   - Four `A` records for the apex domain → `185.199.108.153`,
     `185.199.109.153`, `185.199.110.153`, `185.199.111.153`
   - One `CNAME` for `www` → `USERNAME.github.io`
3. Repo **Settings → Pages → Custom domain**, enter it, wait for the DNS check,
   then tick **Enforce HTTPS** once the certificate is issued (a few minutes)
4. Update `site-url` in `_quarto.yml`

GitHub then 301-redirects `USERNAME.github.io` to the new domain, so old links
keep working. Certificates are free and auto-renewing.

## Keeping it accessible from mainland China

The host is rarely the problem — third-party assets are. Google Fonts, Google
Analytics, Google Scholar badges, Dropbox, Google Drive, and `cdn.jsdelivr.net`
are blocked or unreliable there, and each one stalls page load for every visitor
in China. This site is set up to avoid all of them:

- `theme: [default, ...]` — plain Bootstrap, no Bootswatch Google Fonts import
- `$web-font-path: ""` in `styles.scss` — belt and braces on the same issue
- `html-math-method: plain` — no MathJax/KaTeX CDN fetch
- system font stack, including CJK faces
- no analytics, no Scholar badge, no CDN libraries

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
