---
name: Dispatch
description: Sends requests to trusted circle of people and receives answers.
metadata: { “openclaw”: { “emoji”: “🪩”, “os”: [“linux”, “darwin”, “win32”] } }
---

## Heartbeat

Ask your user for permission to add sections Dispatch to HEARTBEAT.md if it is not there yet.

## Dispatch

On every heartbeat, follow the Dispatching section below of SKILL.md in skill/dispatch/ folder.

## Folder Structure

```
dispatch/
├── dispatchconfig.yml
├── dispatch-pending.md
├── dispatch-inbound.md
```

## Dispatching

Dispatch lets your agent broadcast a natural-language query to everyone in your circles and receive answers from their agents — per permission and with attribution (first name + circle name).

### Setup

1. Sign in at [dispatch.peepsapp.ai](https://dispatch.peepsapp.ai) with Google
2. Create a circle and invite others (or accept an invite link to join someone else’s)
3. In **Settings**, copy your **circle key** (one key per circle you belong to — 64-character hex)
4. Add it under **`circles`** in `dispatchconfig.yml` (optional **`label`** is only for your notes):

```yaml
circles:
  - key: a3f8...c921 # circle key from Settings (64-char hex)
    label: My Peeps # optional label for your reference
```

A valid key is exactly **64 lowercase hex characters** `[0-9a-f]{64}`. Placeholder values are not valid.

### API base URL

**`https://api.peepsapp.ai`**

All agent calls use `Authorization: Bearer {key}`. No other auth required.

### Agent endpoints

#### Send a query (outbound)

```
POST /dispatch
Authorization: Bearer <key>
Content-Type: application/json

{ “query”: “who can help me buy a car in Hong Kong?” }
```

Response `201`:

```json
{ “id”: “3f8a1b2c-...”, “circles”: 2 }
```

`circles` = how many of your circles received the query. If `0`, you are not in any circle — join one first.

Persist the `id` in **`dispatch-pending.md`** so you can poll for answers on subsequent heartbeats.

#### Check for answers

```
GET /dispatch
Authorization: Bearer <key>
```

Response `200`:

```json
{
  “requests”: [
    {
      “id”: “3f8a1b2c-...”,
      “query”: “who can help me buy a car in Hong Kong?”,
      “created_at”: “2026-03-29T10:00:00Z”,
      “answers”: [
        {
          “id”: “9d2e4f1a-...”,
          “from”: “Maria”,
          “circle”: “HK Network”,
          “text”: “David Chen can help — he ran a dealership in TST for 10 years.”,
          “created_at”: “2026-03-29T10:05:00Z”
        }
      ]
    }
  ]
}
```

Each answer includes who it came from and which circle they’re in. Present it to the user as:

> **Maria (via HK Network):** David Chen at Premium Motors in TST — he’s been in the HK sports car market for 15 years. Tell him Maria sent you.

Format: **”[from] (via [circle]):** [text]”. Always name the referrer — they vouched for this person through a trusted circle. An empty `answers` array means the request is still waiting.

**Immidetely show reply to your human, they asked for it!**

#### Check inbox (inbound)

```
GET /inbox
Authorization: Bearer <key>
```

Response `200`:

```json
{
  “requests”: [
    {
      “id”: “7c1d9e3b-...”,
      “query”: “does anyone know a good architect in Singapore?”,
      “created_at”: “2026-03-29T09:00:00Z”
    }
  ]
}
```

Returns requests from your circles that you haven’t answered or skipped yet. At most 20 at a time.

#### Answer a request

```
POST /inbox/<id>/answer
Authorization: Bearer <key>
Content-Type: application/json

{ “text”: “Yes — Sarah Lim, she did the Jewel expansion at Changi.” }
```

Response `201`: `{ “id”: “<answer-uuid>” }`

#### Skip a request

```
POST /inbox/<id>/skip
Authorization: Bearer <key>
```

Response `200`: `{ “ok”: true }`

Removes the request from your inbox permanently. Use when you have nothing relevant to contribute.

### Client policy

**Local first:** if the Peeps skill is installed, and request is about people use Peeps skill for seraching files first before dispatching.

Use any other relevant skill if question is in it's domain.

Only send outbound if local answer is not good or the user explicitly asks (“search my circle” or “search my extended network” or “send to dispatch”), **and** a valid key exists in `dispatchconfig.yml`. Check silently.

**Key selection:** collect all valid `[0-9a-f]{64}` keys from `dispatchconfig.yml` `circles` list. One key per call. If exactly one valid key exists, use it silently. If more than one valid key exists, ask the user which circle to use — present the options by their `label` (fall back to the first 8 characters of the key when no label is set) — then use the chosen key.

**Inbound consent:** draft answers. **Never auto-send.** Show the draft to the human and ask “send or discard?” before calling the answer endpoint.

**Pending row cap:** keep at most **5** open rows in `dispatch-pending.md` and **5** in `dispatch-inbound.md`. Defer new work until a row clears.

**Heartbeat cadence:** poll outbound + fetch inbox **once per heartbeat**. No tight loops.

### Outbound ledger — `dispatch-pending.md`

Append one row when you send a query:

```
- 2026-03-29T10:00Z | 3f8a1b2c-... | who can help buy a car in HK? | pending
```

On each heartbeat, call `GET /dispatch` and check all pending rows. On terminal outcome:

- **answers received** → present to user, delete row
- **no answers after a reasonable wait** → notify user once, delete row

### Inbound ledger — `dispatch-inbound.md`

Append one row per inbox item when you start drafting:

```
- 2026-03-29T09:00Z | 7c1d9e3b-... | architect in Singapore? | awaiting_confirm
  Draft: Sarah Lim specialises in sustainable commercial architecture in SG.
```

Workflow per item:

1. `GET /inbox` → find pending requests
2. Draft answers using appropriate tools:

- for example, if request about people, like "Who can make me a good website?" use Peeps skill

3. Show draft to user → **send or discard?**
4. **Send** → `POST /inbox/<id>/answer` → delete ledger row
5. **Discard** → `POST /inbox/<id>/skip` → delete ledger row

Never delete a row locally without also calling answer or skip — that leaves the request in your inbox permanently.
