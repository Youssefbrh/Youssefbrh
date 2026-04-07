# For Sugar — Romantic Apology Letter Site

A static, mobile-first mini-website for a personal apology letter,
designed to be opened from a QR code.

**No build step required.** Drop the files on any static host and it works.

---

## Project Structure

```
/
├── index.html        ← HTML structure (4 screens)
├── styles.css        ← All visual styles (edit CSS variables to retheme)
├── script.js         ← All logic + CONFIG object (edit here to customize)
├── assets/
│   ├── favicon.svg   ← Small lily icon shown in browser tab
│   └── music.mp3     ← (optional) Add your own ambient music file here
└── README.md
```

---

## ✏️  How to customize

### 1 — Edit the birthday gate

Open `script.js`. Near the top, find `CONFIG.birthday`:

```js
birthday: {
  day:   15,   // ← change to her day of birth
  month: 3,    // ← change to her month (3 = March, 10 = October, etc.)
  year:  2000, // ← change to her 4-digit birth year
},
```

> ⚠️ This is a sentimental gate, **not real security**. The values are
> visible in source code to anyone who looks. The purpose is to create
> a personal moment, not to restrict access.

---

### 2 — Write your letter

In `script.js`, find `CONFIG.letterParagraphs`. Replace the placeholder
text between the two marker comments:

```js
letterParagraphs: [
  // ↓↓ PASTE YOUR LETTER HERE ↓↓

  "Your first paragraph goes here.",
  "Your second paragraph goes here.",
  "Add as many as you need.",

  // ↑↑ END OF LETTER ↑↑
],
```

Each string = one paragraph. Use `\n` inside a string for a line break
within a paragraph.

You can also change:

| Key | What it changes |
|-----|----------------|
| `landingTitle` | The large title on the opening screen |
| `landingSubtitle` | The small subtitle below it |
| `salutation` | The "Dear ___," line |
| `closingSignature` | The sign-off at the bottom of the letter |
| `closingNote` | The final line on the closing screen |

---

### 3 — Change colors

Open `styles.css`. The entire palette lives in the `:root` block at the top:

```css
:root {
  --color-dusty-pink:  #e8b4b8;
  --color-muted-rose:  #c4848c;
  --color-deep-rose:   #9d5a64;
  --color-warm-ivory:  #faf6f0;
  --color-champagne:   #f5e6d3;
  --color-soft-gold:   #d4a86a;
  --color-deep-plum:   #120a18;
  /* … etc. */
}
```

Change any hex value and it will cascade through the whole site.

---

### 4 — Add background music

1. Place your MP3 file at `assets/music.mp3`
2. In `index.html`, find the `OPTIONAL BACKGROUND MUSIC` comment block
   and uncomment the `<audio>` and `<button>` elements inside it
3. In `script.js`, find the `AUDIO BLOCK` comment and remove the
   `/*` and `*/` markers that wrap it

A small ♪ button will appear in the bottom-right corner.
Music **never autoplays** — the user must tap the button.

---

## 🚀 Deployment

### Netlify (recommended — fastest)

1. Go to [netlify.com](https://netlify.com) and sign in
2. Click **Add new site → Deploy manually**
3. Drag the entire project folder into the upload zone
4. Netlify gives you a URL like `https://your-site.netlify.app`

Or via Netlify CLI:
```bash
npm install -g netlify-cli
netlify deploy --dir . --prod
```

---

### Cloudflare Pages

1. Go to [pages.cloudflare.com](https://pages.cloudflare.com)
2. Click **Create a project → Direct Upload**
3. Upload the project folder
4. Your site is live at `https://your-project.pages.dev`

Or connect a GitHub repo and it auto-deploys on every push.

---

### GitHub Pages

1. Push this folder to a GitHub repository
2. Go to **Settings → Pages**
3. Under **Source**, choose **Deploy from a branch**
4. Select `main` branch, root folder `/`
5. Click **Save** — your site is at `https://yourusername.github.io/repo-name`

> If your root path causes issues, move everything into a `/docs` folder
> and choose that as the source instead.

---

## QR Code

Once deployed:

1. Copy your public URL (e.g. `https://your-site.netlify.app`)
2. Go to any free QR generator — for example:
   - [qr-code-generator.com](https://www.qr-code-generator.com)
   - [goqr.me](https://goqr.me)
   - [qrcodemonkey.com](https://www.qrcodemonkey.com)
3. Paste the URL and generate
4. Download as PNG (at least 300×300 px for print clarity)
5. Print it, put it in a card, or frame it alongside a handwritten note

> Tip: test the QR code with your own phone before printing.

---

## Checklist before sharing

- [ ] Updated `CONFIG.birthday` with her actual birthday
- [ ] Replaced placeholder letter text in `CONFIG.letterParagraphs`
- [ ] Read the letter out loud once to make sure it sounds right
- [ ] Tested the birthday gate with the correct date
- [ ] Tested on a real mobile device (not just browser DevTools)
- [ ] Deployed to a live URL
- [ ] Generated and tested the QR code
