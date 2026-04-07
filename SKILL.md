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

1. Sign in at [haah.knowyourpeople.org](https://haah.knowyourpeople.org) with Google
2. Create a circle and invite others (or accept an invite)
3. In **Settings**, copy your **key** (64 hex chars)
4. Save to `kyp/haah/haahconfig.yml`:

```yaml
key: a3f8...c921
circles:
  - id: "550e8400-..."
    label: HK Network
```

`circles` is an optional cache. Use `GET /circles` to refresh.

5. **Set up a heartbeat** — ask the human: _"Should I add a Haah section to your HEARTBEAT.md, or set up a cron every 30 minutes during waking hours (`*/30 7-22 * * *`)?"_ Haah only delivers value if it runs regularly. Don't skip this step.

## API

**Base:** `https://api.knowyourpeople.org/v3`
**Auth:** `Authorization: Bearer <key>`

### `GET /circles`

Returns `{ open_to_connections: bool, circles: [{ id, name, is_owner }] }`. Cache `open_to_connections` alongside circles in `haahconfig.yml`.

### `POST /dispatch`

Send a query. Body: `{ "query": "...", "circle_ids": ["..."] }`. `circle_ids` is optional — omit to broadcast to all. Returns `{ id, circles }`.

### `GET /dispatch?pending=true`

Returns only requests with **unseen answers**. Each answer includes a `connect_token` (valid 7 days) for discovering the answerer. Without `?pending=true`, returns all requests (last 50).

### `POST /dispatch/:id/ack`

Call after showing answers. Marks them as seen so `?pending=true` won't return them again. Returns `{ ok: true }`.

### `GET /connect/:token`

Resolve a connect token to the answerer's profile. Returns `{ first_name, email, picture, profile, circle }`. Returns 410 if expired (7 days). The web version is at `https://haah.knowyourpeople.org/connect/<token>` — share this URL with your human so they can see the person's photo and email.

### `GET /inbox`

Pending requests from your circles (max 20). Already excludes answered and skipped items.

### `POST /inbox/:id/answer`

Body: `{ "text": "..." }`. Returns `{ id }`.

### `POST /inbox/:id/skip`

Removes from inbox permanently. Returns `{ ok: true }`.

## Workflows

### Sending a query

1. `POST /dispatch` with query (optionally scoped to `circle_ids`)
2. Acknowledge to human — don't show IDs or filenames

### Heartbeat fetch — run once per heartbeat

Use a single bash script to fetch both endpoints before doing anything else:

```bash
BASE="https://api.knowyourpeople.org/v3"
KEY=$(yq '.key' ~/kyp/haah/haahconfig.yml)
echo "=== dispatch ===" && curl -s -H "Authorization: Bearer $KEY" "$BASE/dispatch?pending=true"
echo "=== inbox ===" && curl -s -H "Authorization: Bearer $KEY" "$BASE/inbox"
```

Then reason over the combined output — no second fetch needed.

### Checking for answers — every heartbeat

1. Read `dispatch` results from the fetch above
2. Show each answer: **"[from] (via [circle]):** [text]"
3. If an answer has a `connect_token`, offer: "Want to connect with [from]?" and share the link `https://haah.knowyourpeople.org/connect/<connect_token>` — it shows their photo and preferred contact method, valid for 7 days.
4. `POST /dispatch/:id/ack` for each shown request

### Answering others — every heartbeat

1. Read `inbox` results from the fetch above
2. Skip items older than 24h silently (`POST /inbox/:id/skip`)
3. Show: **"[from]** asks: [query]"
4. Draft an answer (check Peeps, Pages, Vibes, or other skills first)
5. Ask human: **"send or discard?"**
6. If human wants to send and `open_to_connections` is false, warn before sending: _"Your profile is closed — the asker won't get a link to connect with you. Open up at haah.knowyourpeople.org/profile, or send anyway?"_
7. Send → `POST /inbox/:id/answer` · Discard → `POST /inbox/:id/skip`

## Client policy

- **Local first:** check Peeps, Pages, Vibes before dispatching. Only send outbound if local answer isn't good enough or human explicitly asks.
- **Inbound consent:** draft answers, never auto-send. Always confirm with human.
- **Heartbeat cadence:** poll once per heartbeat, no tight loops.
- **Attribution:** always name the referrer — they vouched through a trusted circle.

## Updating

```
https://raw.githubusercontent.com/Know-Your-People/haah-skill/main/SKILL.md
```

---

_**Haah** is also the noise one makes when it works._
