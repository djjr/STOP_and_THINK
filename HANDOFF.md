# Stop + Think — Developer Handoff

Last updated: May 2026. Documents the architecture, current state, known issues, and pending work for the stop_and_think project.

---

## Architecture

```
stop_and_think/
├── index.html        # Student app (static, no server needed for students)
├── stdata.js         # Question data (deployed separately to server)
├── editor.html       # Teacher editor (served locally by Flask)
├── server.py         # Flask server on port 5742
├── start.command     # Double-click launcher: kills port, starts Flask, opens browser
├── deploy.command    # Standalone SFTP deploy of stdata.js only
├── review.html       # Older tag-selector page (see Known Issues)
└── open-editor.command  # Obsolete — use start.command instead
```

### Data flow

1. Teacher runs `start.command` → Flask starts on `localhost:5742`
2. `editor.html` is served at `/` — loads `stdata.js` at startup
3. Teacher edits questions → clicks **Deploy ↑** → Flask POSTs stdata.js via SFTP to server
4. Students access live URL with a `?q=…` parameter
5. `index.html` reads `stdata.js` (same-directory script tag), shows questions one at a time
6. Student responses saved to `localStorage`, exported via Export Answers button

---

## Server / Deploy Config

| Setting | Value |
|---------|-------|
| Flask port | 5742 |
| SFTP user | `danryane` |
| SFTP host | `innoeduvation.org` |
| Remote path | `/home/danryane/public_html/danryan/production/teaching/stop_and_think/stdata.js` |
| SSH key | `~/.ssh/id_ed25519` |
| Live base URL | `https://innoeduvation.org/danryan/production/teaching/stop_and_think/index.html` |

Deploy uses `sftp -b batchfile` (temp file, cleaned up in `finally`). Auth is via SSH key — no password.

---

## Editor (editor.html)

Full single-page app served by Flask.

### State variables
```js
let questions = [];            // in-memory copy of all questions
let selectedTags = new Set();  // active AND-filter tags
let displayedQuestions = [];   // filtered + drag-reordered subset
let excludedNums = new Set();  // question numbers unchecked from URL output
let editingNumber = null;      // number | 'new' | null (modal state)
let pendingNewNumber = null;   // assigned number for new question
const BASE = 'https://innoeduvation.org/…/index.html';
```

### Panels
1. **Tag Filter** — pill buttons, AND logic. Pruned automatically if a tag is removed from all questions.
2. **Question List** — shows filtered questions with drag handles, checkboxes, tag chips, Edit button.
   - Checkboxes (green, checked by default) — uncheck to exclude from generated URL without removing from list
   - ✓ All / ✕ None buttons toggle all checkboxes in the current filtered view
   - Drag-and-drop reorders `displayedQuestions` (affects URL order, not the master `questions` array)
3. **Generated URL** — live-updated as questions are filtered/reordered/toggled. Checkbox to add `&slides=true`.
   - Copy URL, Copy as `<iframe>`, Preview buttons
4. **Preview** — hidden iframe panel, loads current URL

### Edit modal
- Rich text editor (RTE) for Question and Answer fields
- Visual mode (contenteditable) ↔ HTML source toggle
- Tag editor with autocomplete from existing tags
- Cmd/Ctrl+S saves the edit

### Save vs Deploy
- **Save** — POSTs to `/api/save` → writes `stdata.js` to disk only
- **Deploy** — POSTs to `/api/deploy` → writes to disk AND SFTPs to server

### Serialize format
```js
'window.stopThinkQuestions = [\n' + rows.join(',\n') + '\n];\n'
// Each row: '   ' + JSON.stringify({number, question, answer, tags})
```

---

## Student App (index.html) — Key Details

### Question rendering
- `entry.question` and `entry.answer` are raw HTML strings — rendered with `innerHTML` (not `innerText`)
- Questions may contain `<img>` tags; images are constrained to `max-width: 100%`
- Label is "STOP + THINK" (red/green) normally, "PONDER THIS" (green) in preRead mode

### Answer gate
- `<details>` element requires 14+ chars in textarea before it can be opened
- Bypassed entirely when `slides=true` or slides is a deck name
- `event.preventDefault()` on the summary click prevents toggle if gate not met

### localStorage schema
```
stopthink_q_{N}        → student's typed answer (string)
stopthink_q_{N}_time   → ISO 8601 timestamp of last keystroke (string)
```

### slides parameter
```js
isSlidesMode()   // true if slides param is any truthy non-false value
getDeckName()    // null if no slides; 'unknown' if slides=true; deck name otherwise
```

### Export output includes
- **Deck:** header (if slides param present)
- Question text (HTML stripped via temp div)
- `[Last answered: …]` per question (from `_time` localStorage key)
- Plain text and Markdown formats

---

## Drag-and-Drop Notes

Event delegation on `#q-list` container (not per-item listeners). Child elements that would intercept drag events have `pointer-events: none` in CSS. Checkboxes explicitly have `pointer-events: auto` to override this. Dropping reorders `displayedQuestions` only — the master `questions` array is untouched until Save/Deploy.

---

## Known Issues / Debt

### review.html references missing file
`review.html` uses `<script src="stop_and_think.js">` which does not exist. Should be `stdata.js`. This file predates the current architecture and is not actively used.

### index.html not wired into deploy
The deploy button and `deploy.command` only upload `stdata.js`. Changes to `index.html` must be uploaded manually via SFTP. To fix: add a second `sftp put` in `deploy.command` and a second write in `server.py`'s `/api/deploy` route.

### open-editor.command is obsolete
Opens `editor.html` directly as a file:// URL, bypassing Flask. The editor requires Flask for Save/Deploy. Use `start.command` instead. Safe to delete.

### index1.1.6.html / indexOLD.html
Both are empty (0 bytes). Safe to delete.

---

## Pending / Nice-to-Have

- [ ] Wire `index.html` into the deploy pipeline alongside `stdata.js`
- [ ] Fix `review.html` script src (`stop_and_think.js` → `stdata.js`)
- [ ] Add a "Delete question" button to the editor modal
- [ ] Add question number renumbering UI (currently done manually in stdata.js)
- [ ] Consider a `/api/deploy-all` endpoint that uploads both stdata.js and index.html

---

## Starting the Editor

```bash
# From Finder: double-click start.command
# Or from terminal:
cd /Users/danryan/Documents/danryan-dropbox-link/production/teaching/stop_and_think
python3 server.py
# then open http://localhost:5742
```

Flask checks for existing process on port 5742 and kills it. Requires `flask` (`pip3 install flask`); `start.command` auto-installs it if missing.

---

## Recent Changes (May 2026)

- Navigation buttons moved above question text (stable position regardless of question length)
- Button styles lightened (smaller, outlined, grey)
- `innerText` → `innerHTML` for answer display so HTML renders correctly
- Editor: per-question checkboxes to include/exclude from generated URL
- Editor: ✓ All / ✕ None toggle buttons in URL panel
- `slides` URL param now accepts deck names (e.g. `slides=week3`) in addition to `true`/`false`
- Timestamps saved to localStorage on every answer keystroke
- Export (plain text + markdown) includes deck name and per-question timestamps
- "Copy as Markdown" button added to Export Answers panel
