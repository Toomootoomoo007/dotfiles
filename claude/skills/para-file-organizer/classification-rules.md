# PARA Classification Rules — Edge Cases & Examples

## Contents
- Project vs Area disambiguation
- Resource vs Archive disambiguation
- Screenshot / image classification
- Ephemeral file detection
- Common file type heuristics

---

## Project vs Area Disambiguation

The hardest boundary. Use these signals:

| Signal | Lean Project (10_) | Lean Area (20_) |
|--------|--------------------|-----------------|
| Deadline exists | ✓ | — |
| Goal has a done-state ("launch", "pass", "submit") | ✓ | — |
| Recurring / maintenance language ("manage", "track", "maintain") | — | ✓ |
| No end date implied | — | ✓ |
| One-time deliverable | ✓ | — |
| Standard of living to uphold | — | ✓ |

**Examples:**
- `portfolio-site-v2.md` → **Project** (has a launch goal)
- `health-habits.md` → **Area** (ongoing maintenance)
- `tax-2025.md` → **ASK** (could be Project if planning, Archive if filed)
- `home-finances.md` → **Area** (ongoing responsibility) *unless* it's a specific budget project

**Rule:** If you cannot identify a concrete done-state, it's an Area.

---

## Resource vs Archive Disambiguation

| Signal | Resource (30_) | Archive (99_) |
|--------|----------------|---------------|
| Still actively referenced | ✓ | — |
| Topic still interests the user | ✓ | — |
| Associated project/area is active | ✓ | — |
| Project is complete | — | ✓ |
| Interest has clearly passed (e.g. old job, old tech) | — | ✓ |
| Dated > 2 years ago with no recent edits | lean Archive | — |

**Examples:**
- `rust-async-notes.md` (recent edits) → **Resource**
- `2022-internship-notes.md` (no edits since) → **Archive**
- `reading-list.md` → **Resource**

---

## Screenshot / Image Classification

| Filename / content clue | Classification |
|------------------------|---------------|
| Shows error message related to active project | **Project** subfolder |
| Reference diagram (architecture, UI pattern) | **Resource** |
| Notification / alert / system popup | **Archive** (ephemeral) |
| Meme / reaction image | **Archive** (ephemeral) |
| App receipt / confirmation | **Archive** |
| Purpose completely unknown | **ASK** |

---

## Ephemeral File Detection (auto-decide → Archive)

Auto-classify to `99_Archive/` without asking when:
- Filename contains: `notification`, `alert`, `download`, `temp`, `tmp`, `IMG_XXXX`, `Screenshot XXXX`
- Content is a system notification or transactional email screenshot
- File is a meme (detected by filename pattern or obvious content)
- File clearly belongs to a completed/past period (e.g. `2020-goals.md` with no recent edits)

---

## Common File Type Heuristics

| File type / pattern | Default lean |
|--------------------|-------------|
| `*.pdf` with date in name | Archive (if past) / ASK (if current) |
| `meeting-notes-YYYY-MM-DD.md` | Archive if > 6 months old, else Project/Area |
| `README.md`, `index.md` | Keep in current folder; do not relocate without asking |
| Template files (`_template.md`, `template-*.md`) | Do not move; skip with note |
| Daily notes (`YYYY-MM-DD.md`) | Do not move; skip with note |
| `.canvas` files | Do not move; skip with note |

---

## Multiple Active Projects Edge Case

When a file could belong to two active projects:
1. Check if one project is clearly primary
2. If unclear → **ASK** with both options listed
3. Suggest the user create a shared `30_Resources/` note instead of duplicating

---

## Vault-Specific Folders to Skip

Always skip (do not classify, do not move):
- `.obsidian/`
- `templates/` or `_templates/`
- `attachments/` or `assets/` (media files)
- Daily notes folders (configured by user)
- Any folder starting with `_` (conventionally "system" folders)

If uncertain whether a folder is system-managed, **ask before touching it.**
