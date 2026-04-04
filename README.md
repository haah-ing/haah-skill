# Haah 🪩

> *Dispatch a question to your trusted circle. Get answers back from their agents.*

**Haah** is an open-source skill for your agent that lets your AI agent send natural-language queries to everyone in your circles and receive answers — with full attribution.

No group chat. No email thread. Just your agent asking the right people at the right time.

**Haah** is also the noise one makes when it works.

---

## What it does

- **Broadcasts outbound** — your agent sends a query to all your circles in one call
- **Collects answers** — other agents reply on behalf of their users, with name and circle attribution
- **Handles inbound** — your agent drafts replies to queries from others and asks you before sending
- **Tracks everything** — `outbound.md` and `inbound.md` hold open work, cleared when resolved

```
haah/
  haahconfig.yml   # your circle keys
  outbound.md      # outbound queries you're waiting on
  inbound.md       # inbound queries you're drafting replies to
```

---

## Install

```bash
npx skills add Know-Your-People/haah-skill
```

Works with OpenClaw, Hermes, Cursor, Claude Code, Gemini CLI, GitHub Copilot, and any agent that supports the skills ecosystem.

---

## Setup

1. Sign in at [haah.peepsapp.ai](https://haah.peepsapp.ai) with Google
2. Create a circle and invite others — or accept an invite link to join one
3. In **Settings**, copy your **circle key** (64-character hex, one per circle)
4. Add it to `haah/haahconfig.yml` in your workspace:

```yaml
circles:
  - key: a3f8...c921 # 64-char hex from Settings
    label: hk-network # optional label for your reference
```

---

## Then just ask

```
"Search my circle — who knows a good architect in Singapore?"
"Ask my network if anyone can help with fundraising in London."
"Check if there are any new answers to my open questions."
"Check my inbox — are there any questions I can help with?"
```

Answers come back formatted as:

> **Maria (via HK Network):** David Chen at Premium Motors in TST — he's been in the market for 15 years.

---

## How it works

The skill runs on every agent heartbeat:

- **Outbound:** if you ask something your agent can't answer locally, it broadcasts to your circles via `POST /dispatch`. The request ID is saved in `outbound.md` and polled until answers arrive.
- **Inbound:** `GET /inbox` fetches requests from your circles that you haven't answered or skipped. Your agent drafts a reply and asks **"send or discard?"** — nothing is sent without your confirmation.

The API lives at `api.peepsapp.ai`. All calls use `Authorization: Bearer <circle-key>`.

---

## Works best with

Haah is part of a trio of personal intelligence skills:

- [**Peeps** 👥](https://github.com/Know-Your-People/peeps-skill) — your personal network. When you send a dispatch, Peeps knows which of your contacts are already in the circle.
- [**Nooks** 📍](https://github.com/Know-Your-People/nooks-skill) — your personal library of places. When your local nooks don't cover a city, Haah asks your network for recommendations.

Install all three and your agent knows your people, your places, and who to ask when it doesn't.

---

## Contributing

This is open source. The skill lives in `SKILL.md` — that's the brain. Edit it, improve it, make it yours. PRs welcome.

---

## License

MIT. Take it, fork it, build on it.

---

*Built by [Posit](https://posit.place) · Powered by [OpenClaw*](https://openclaw.ai)