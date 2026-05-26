# Stop-and-Think Upgrade Instructions

## Context

`stop-and-think.html` is a self-contained student response tool embedded as iframes
inside Reveal.js slide decks (via Obsidian Slides Extended). Students type answers
to open-ended questions, can reveal a model answer, and can export all their answers.

The file loads question data from `stdata.js`, which exposes `window.stopThinkQuestions`
as an array of `{ number, question, answer }` objects.

Current version: **v1.1.8**
Target version: **v1.2.0**

---

## What to change

### 1. Storage format: plain string → JSON

Currently, answers are stored as plain strings:
```javascript
localStorage.setItem(`stopthink_q_${entry.number}`, responseBox.value);
const saved = localStorage.getItem(key) || "";
```

Replace this with two helper functions:

**`loadEntry(key)`** — reads and parses, with fallback for legacy plain strings:
```javascript
function loadEntry(key) {
  const raw = localStorage.getItem(key);
  if (!raw) return { answer: "", deck: "unknown", updated: null };
  try {
    const parsed = JSON.parse(raw);
    if (typeof parsed === "object" && parsed !== null) return parsed;
    return { answer: String(parsed), deck: "unknown", updated: null };
  } catch {
    return { answer: raw, deck: "unknown", updated: null };
  }
}
```

**`saveEntry(key, answerText)`** — writes JSON with deck and timestamp:
```javascript
function saveEntry(key, answerText) {
  localStorage.setItem(key, JSON.stringify({
    answer:  answerText,
    deck:    getDeckId(),
    updated: Date.now()
  }));
}
```

Replace every `localStorage.setItem(key, ...)` call with `saveEntry(key, ...)`.
Replace every `localStorage.getItem(key)` used to populate the textarea with
`loadEntry(key).answer`.

---

### 2. Add getDeckId()

Add this function alongside the other query param helpers:
```javascript
function getDeckId() {
  return getQueryParam("deck") || "default";
}
```

The `deck` param is set in the iframe's URL by the slide author, e.g. `?q=3,7&deck=Week4`.
It identifies which presentation a question was answered in and is stored inside
each localStorage value.

---

### 3. Pass `deck` through the Next button

In `renderNav`, the Next button builds a new URL. It currently passes `preRead`,
`debug`, and `slides`. Add `deck` to that list. Ideally refactor to a loop:
```javascript
["preRead", "debug", "slides", "deck"].forEach(p => {
  const v = getQueryParam(p);
  if (v) params.set(p, v);
});
```

---

### 4. Update collectAllAnswers()

Currently returns a formatted string. Change it to return an **array of structured objects**:

```javascript
function collectAllAnswers() {
  return Object.keys(localStorage)
    .filter(k => k.startsWith("stopthink_q_"))
    .sort((a, b) => {
      const n = k => parseInt(k.replace("stopthink_q_", ""));
      return n(a) - n(b);
    })
    .map(key => {
      const num    = parseInt(key.replace("stopthink_q_", ""));
      const card   = window.stopThinkQuestions.find(q => q.number === num);
      const stored = loadEntry(key);
      return {
        num,
        question:    card   ? card.question : `Question ${num}`,
        modelAnswer: card   ? card.answer   : "(model answer unavailable)",
        myAnswer:    stored.answer  || "(no response)",
        deck:        stored.deck    || "unknown",
        updated:     stored.updated || null
      };
    });
}
```

---

### 5. Add formatting helpers

```javascript
function formatDate(ms) {
  if (!ms) return "unknown date";
  return new Date(ms).toLocaleString(undefined, {
    month: "short", day: "numeric", year: "numeric",
    hour: "numeric", minute: "2-digit"
  });
}

function answersAsText(entries) {
  const bar = "─".repeat(40);
  return entries.map(e =>
    `[${e.deck}  ·  ${formatDate(e.updated)}]\n` +
    `Q${e.num}: ${e.question}\n\n` +
    `You: ${e.myAnswer}\n\n` +
    `Model: ${e.modelAnswer}`
  ).join(`\n\n${bar}\n\n`);
}
```

Update `downloadAnswers()` to call `answersAsText(collectAllAnswers())`.

---

### 6. Replace showAnswersInline() with styled card display

Remove the existing `<pre>`-based display. Replace with a card-per-question layout.
The container should be rebuilt fresh each time Export is clicked so updated answers
appear immediately without a page reload.

Each card shows:
- A metadata row: deck name (styled as a colored badge) + formatted timestamp
- The question text
- Student answer with a left border in red (`#ba372a`)
- Model answer with a left border in green (`#377437`)

Buttons at the top of the export panel:
- **Copy as Text** — copies `answersAsText(entries)` to clipboard, with fallback
- **Download .txt** — calls `downloadAnswers()`

---

### 7. Add CSS for cards

Add to the `<style>` block:

```css
#inline-answers {
  width: 90vw;
  max-width: 600px;
  margin-top: 2em;
}
#inline-answers h3 {
  color: #444;
  font-size: 1em;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 0.75em;
}
.answer-card {
  border: 1px solid #e0e0e0;
  border-radius: 6px;
  padding: 0.75em 1em;
  margin-bottom: 1em;
  background: #fafafa;
}
.card-meta {
  font-size: 0.75em;
  color: #888;
  margin-bottom: 0.4em;
  display: flex;
  gap: 0.75em;
  flex-wrap: wrap;
  align-items: center;
}
.deck-tag {
  background: #e8f0fe;
  color: #3c4ead;
  border-radius: 3px;
  padding: 1px 6px;
  font-weight: 600;
}
.card-question {
  font-size: 0.95em;
  font-weight: 600;
  color: #333;
  margin-bottom: 0.6em;
}
.card-section-label {
  font-size: 0.75em;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  margin-bottom: 0.2em;
}
.card-student-label { color: #ba372a; }
.card-model-label   { color: #377437; }
.card-student-answer {
  font-size: 0.9em;
  color: #333;
  white-space: pre-wrap;
  margin-bottom: 0.75em;
  padding: 0.4em 0.6em;
  background: #fff;
  border-left: 3px solid #ba372a;
}
.card-model-answer {
  font-size: 0.9em;
  color: #377437;
  white-space: pre-wrap;
  padding: 0.4em 0.6em;
  background: #fff;
  border-left: 3px solid #377437;
}
.export-buttons {
  display: flex;
  gap: 0.5em;
  margin-bottom: 1em;
  flex-wrap: wrap;
}
```

---

## Acceptance criteria

- [ ] Answering a question writes `{ answer, deck, updated }` JSON to localStorage
- [ ] Legacy plain-string values in localStorage load without error
- [ ] `deck` param is passed forward by the Next button
- [ ] Export shows one styled card per question across all decks
- [ ] Each card displays deck badge, timestamp, student answer, and model answer
- [ ] `(no response)` appears for unanswered questions
- [ ] Copy as Text and Download .txt both produce readable plaintext with deck + date headers
- [ ] Version tag updated to v1.2.0
