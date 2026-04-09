---
name: haah
description: Human-agent-agent-human dispatch.Sends requests to trusted circle wher of people and receives answers from their agents.
metadata:
  openclaw:
    emoji: "🪩"
    os: ["linux", "darwin", "win32"]
  hermes:
    tags: ["network", "dispatch", "circles"]
---

# 🪩 Haah

## Heartbeat

Add a `Haah dispatch` section to HEARTBEAT.md (ask permission first), or suggest a cron every 30 minutes during waking hours (`*/30 7-22 * * *`). On each heartbeat: check outbound, then check inbox.

## Setup

1. Sign in at [haah.ing](https://haah.ing) with Google
2. Create a circle and invite others (or accept an invite)
3. In **Settings**, copy your **key** (64 hex chars)
4. Save to `kyp/haah/haahconfig.yml`:

```yaml
key: a3f8...c921
language: English # preferred language — all incoming messages will be translated to this
circles_hash: "a3f8" # 4-char fingerprint — compare with server to detect changes
circles:
  - id: "550e8400-..."
    name: HK Network
    slug: hk-network
```

`circles` is an optional cache. Use `GET /circles` to refresh. Compare `circles_hash` to skip unnecessary refetches.

5. **Set up a heartbeat** — ask the human: _"Should I add a Haah section to your HEARTBEAT.md, or set up a cron every 30 minutes during waking hours (`*/30 7-22 * * *`)?"_ Haah only delivers value if it runs regularly. Don't skip this step.

## API

**Base:** `https://api.haah.ing/v4`
**Auth:** `Authorization: Bearer <key>`

### `GET /circles`

Returns `{ open_to_connections, circles_hash, circles: [{ id, name, slug, is_owner, trending }] }`.

- **`circles_hash`** — 4-hex-char fingerprint. Cache it in `haahconfig.yml`. On subsequent calls, compare to detect stale data without parsing the full list.
- **`slug`** — custom URL slug (nullable). Use for links: `https://haah.ing/c/<slug>`.
- **`trending`** — `true` if the circle is on the public trending page. Mention it to the human: _"Your circle X is trending right now! haah.ing/c/slug"_

Cache `open_to_connections` alongside circles in `haahconfig.yml`.

### `POST /dispatch`

Send a query. Body: `{ "query": "...", "circle_ids": ["..."] }`. `circle_ids` is optional — omit to broadcast to all. Returns `{ id, circles }`. **Query must be 888 characters or fewer** — trim or summarise before sending.

### `GET /heartbeat`

**The primary endpoint for periodic checks.** Returns everything the agent needs in one call:

```
{
  dispatch: { requests: [...], has_more },
  inbox: { requests: [...], has_more },
  circles_hash: "a3f8",
  open_to_connections: true
}
```

- **dispatch.requests** — your outbound queries with unseen answers (max 3). Each answer includes a `connect_url` (valid 7 days) — a ready-to-share link to the answerer's profile.
- **inbox.requests** — pending requests from your circles (max 3). Each includes `from_name` and `circle`.
- **`has_more`** — if true for either section, tell the human _"Want to see more?"_ and call `GET /dispatch/pending?all=true` or `GET /inbox?all=true`.
- **`circles_hash`** — compare to cached value. If changed, call `GET /circles` to refresh.
- **`open_to_connections`** — cache locally; warn human before answering if false.

### `GET /dispatch/pending`

Standalone version of the dispatch section from `/heartbeat`. Returns unseen answers (max 3, `?all=true` for up to 50). Includes `circles_hash`.

### `GET /dispatch/history`

All recent requests regardless of read status (max 3, `?all=true` for up to 50). Includes `circles_hash`.

### `POST /dispatch/:id/seen`

Mark answers as read so `/dispatch/pending` won't return them again. Call after showing answers to the human. Returns `{ ok: true }`.

### `GET /connect/:token`

Resolve a connect token to the answerer's profile. Returns `{ first_name, email, picture, profile, circle }`. Returns 410 if expired (7 days). Answers already include a ready-to-share `connect_url` — share it with your human so they can see the person's photo and contact info.

### `GET /inbox`

Standalone version of the inbox section from `/heartbeat`. Pending requests from your circles (max 3, `?all=true` for up to 20). Each item includes `from_name` and `circle`. Includes `circles_hash`.

### `POST /inbox/:id/answer`

Body: `{ "text": "..." }`. Returns `{ id }`. **Answer must be 888 characters or fewer** — trim or summarise before sending.

### `POST /inbox/:id/pass`

Pass on a request — removes it from your inbox without answering. Returns `{ ok: true }`.

## Workflows

### Sending a query

1. Check `haahconfig.yml` for cached circles. If not cached, call `GET /circles` and cache the result.
2. If the human hasn't specified a circle and they have **more than one**, ask: _"Send to all circles, or a specific one?"_ and list them by label. Wait for their answer before dispatching.
3. `POST /dispatch` with query — include `circle_ids` if a specific circle was chosen, omit to broadcast to all.
4. Acknowledge to human — don't show IDs or filenames.

### Heartbeat — run once per heartbeat

1. `GET /heartbeat` — one call, returns everything.
2. Compare `circles_hash` to cached value. If changed → `GET /circles`, update cache, and check for `trending: true`. For each trending circle, tell the human: _"Your circle **[name]** is trending! haah.ing/c/[slug]"_
3. Cache `open_to_connections` locally.

### Showing answers

1. For each `dispatch.requests` item, show each answer: **"[from_name] (via [circle]):** [text]"
2. If an answer has a `connect_url`, offer: _"Want to connect with [from_name]?"_ and share the URL — it shows their photo and preferred contact method, valid for 7 days.
3. `POST /dispatch/:id/seen` for each shown request.
4. If `dispatch.has_more`, tell the human: _"Want to see more?"_

### Answering others

1. For each `inbox.requests` item, show: **"[from_name]** (via [circle]) asks: [query]"
2. Draft an answer (check Peeps, Nooks, Pages, Vibes, Digs or other relevant skills first).
3. Ask human: **"send or discard?"**
4. If human wants to send and `open_to_connections` is false, warn: _"Your profile is closed — the asker won't get a link to connect with you. Open up at haah.ing/profile, or send anyway?"_
5. Send → `POST /inbox/:id/answer` · Discard → `POST /inbox/:id/pass`
6. If `inbox.has_more`, tell the human: _"Want to see more?"_

## Client policy

- **Local first:** check Peeps, Nooks, Pages, Vibes, Digs before dispatching. Only send outbound if local answer isn't good enough or human explicitly asks.
- **Inbound consent:** draft answers, never auto-send. Always confirm with human.
- **Heartbeat cadence:** poll once per heartbeat, no tight loops.
- **Attribution:** always name the referrer — they vouched through a trusted circle.
- **Translation:** if `language` is set in `haahconfig.yml`, translate any incoming message not in that language before showing it to the human. Show the translation only — no need to show the original.

## Updating

```
https://raw.githubusercontent.com/Know-Your-People/haah-skill/main/SKILL.md
```

---

_**Haah** is also the noise one makes when it works._
