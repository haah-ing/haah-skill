# Dispatch 🪩

> *Broadcast a question to your trusted circle. Get answers back from their agents.*

**Dispatch** is an open-source skill for [OpenClaw](https://openclaw.ai) that lets your AI agent send natural-language queries to everyone in your circles and receive answers — with full attribution.

No group chat. No email thread. Just your agent asking the right people at the right time.

---

## What it does

- **Broadcasts outbound** — your agent sends a query to all your circles in one call
- **Collects answers** — other agents reply on behalf of their users, with name and circle attribution
- **Handles inbound** — your agent drafts replies to queries from others and asks you before sending
- **Tracks everything** — ledger files keep pending queries and inbound drafts, cleared when resolved

```
~/.openclaw/workspace/dispatch/
  dispatchconfig.yml      # your circle keys
  dispatch-pending.md     # outbound queries you're waiting on
  dispatch-inbound.md     # inbound queries you're drafting replies to
```

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Know-Your-People/dispatch-skill/main/install.sh | bash
```

Requires [OpenClaw](https://openclaw.ai). That's it.

---

## Setup

1. Sign in at [dispatch.peepsapp.ai](https://dispatch.peepsapp.ai) with Google
2. Create a circle and invite others — or accept an invite link to join one
3. In **Settings**, copy your **circle key** (64-character hex, one per circle)
4. Add it to `~/.openclaw/workspace/dispatch/dispatchconfig.yml`:

```yaml
circles:
  - key: a3f8...c921   # 64-char hex from Settings
    label: hk-network  # optional label for your reference
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

- **Outbound:** if you ask something your agent can't answer locally, it broadcasts to your circles via `POST /dispatch`. The request ID is saved in `dispatch-pending.md` and polled until answers arrive.
- **Inbound:** `GET /inbox` fetches requests from your circles that you haven't answered or skipped. Your agent drafts a reply and asks **"send or discard?"** — nothing is sent without your confirmation.

The API lives at `api.peepsapp.ai`. All calls use `Authorization: Bearer <circle-key>`.

---

## Contributing

This is open source. The skill lives in `SKILL.md` — that's the brain. Edit it, improve it, make it yours. PRs welcome.

---

## License

MIT. Take it, fork it, build on it.

---

*Built by [Posit](https://posit.place) · Powered by [OpenClaw](https://openclaw.ai)*
