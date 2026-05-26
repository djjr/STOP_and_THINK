# Stop + Think

A lightweight classroom Q&A tool. Students work through a curated set of questions one at a time, type a response, then reveal a suggested answer to compare. Answers are saved locally in the browser.

---

## How It Works

Questions are presented one at a time via URL. Students type a short response, then click **Compare your response** to see the suggested answer. Navigation buttons move through the sequence. All typed responses are saved to `localStorage` automatically.

---

## Live URL

```
https://innoeduvation.org/danryan/production/teaching/stop_and_think/index.html?q=100
```

---

## URL Parameters

| Parameter | Values | Effect |
|-----------|--------|--------|
| `q` | `1,5,12,34` | Comma-separated question numbers to show |
| `i` | `0`, `1`, `2`… | Starting index into the `q` list (default: 0) |
| `slides` | absent / `false` | Normal mode |
| `slides` | `true` | Slides mode (larger text, answer gate bypassed) |
| `slides` | `sociology101` | Slides mode + deck name appears in exports |
| `preRead` | `true` | Replaces "STOP + THINK" label with "PONDER THIS"; answer says "Read the reading!" |
| `debug` | `yes` | Shows the question number sequence on screen |

### Example URLs

```
# Five questions, normal mode
index.html?q=1,5,12,34,67

# Slides mode with deck name
index.html?q=1,5,12,34&slides=durkheim-week3

# Pre-reading ponder prompt
index.html?q=4,8,22&preRead=true
```

---

## Student Features

- **Navigation button** (top of page) — advances through the question sequence, wraps around
- **Response box** — free-text, auto-saved to `localStorage` on every keystroke
- **Compare your response** — expandable; requires typing at least 14 characters first (bypassed in slides mode)
- **Export Answers** — shows all typed responses for the current session's question set, with:
  - **Copy to Clipboard** — plain text with deck name and timestamps
  - **Copy as Markdown** — formatted with `##` headings, italicized timestamps, `---` dividers
  - **Select All** — selects text for manual copy

---

## Editing Questions

Use the editor (see [HANDOFF.md](HANDOFF.md)) to create, edit, reorder, and tag questions, then deploy the updated data file.

---

## Data File

`stdata.js` — loaded as a `<script>` tag. Format:

```js
window.stopThinkQuestions = [
   {"number": 5, "question": "What is anomie?", "answer": "A breakdown of social norms…", "tags": ["Durkheim", "anomie"]},
   ...
];
```

- Questions can contain HTML (images, bold, etc.)
- Numbers do not need to be sequential but must be unique
- Tags drive the editor's filter and URL-builder

---

## Files

| File | Purpose |
|------|---------|
| `index.html` | Student-facing app |
| `editor.html` | Question editor (served by Flask) |
| `server.py` | Local Flask server on port 5742 |
| `start.command` | Double-click to start server and open editor |
| `deploy.command` | Standalone SFTP deploy of `stdata.js` |
| `stdata.js` | All question data |
| `review.html` | Older tag-selector page (loads index.html in iframe) |
| `study/` | Study materials directory |
