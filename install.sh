#!/usr/bin/env bash
set -euo pipefail

SKILL_REPO="git@github.com:Know-Your-People/dispatch-skill.git"
SKILL_WEB="https://github.com/Know-Your-People/dispatch-skill"
SKILL_RAW="https://raw.githubusercontent.com/Know-Your-People/dispatch-skill/main"
SKILLS_DIR="${HOME}/.openclaw/workspace/skills/dispatch"
DISPATCH_DIR="${HOME}/.openclaw/workspace/dispatch"

GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
BOLD=$'\033[1m'
NC=$'\033[0m'

link() {
  printf '\033]8;;%s\033\\%s\033]8;;\033\\' "$1" "${2:-$1}"
}

echo ""
echo -e "${GREEN}  ██████╗ ██╗███████╗██████╗  █████╗ ████████╗ ██████╗██╗  ██╗${NC}"
echo -e "${GREEN}  ██╔══██╗██║██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██║  ██║${NC}"
echo -e "${GREEN}  ██║  ██║██║███████╗██████╔╝███████║   ██║   ██║     ███████║${NC}"
echo -e "${GREEN}  ██║  ██║██║╚════██║██╔═══╝ ██╔══██║   ██║   ██║     ██╔══██║${NC}"
echo -e "${GREEN}  ██████╔╝██║███████║██║     ██║  ██║   ██║   ╚██████╗██║  ██║${NC}"
echo -e "${GREEN}  ╚═════╝ ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝${NC}"
echo ""
echo "  Broadcast a question to your trusted circle. Get answers back."
echo "  ──────────────────────────────────────────"
echo ""

# Check OpenClaw is installed
if ! command -v openclaw &> /dev/null; then
  echo -e "${RED}✗ OpenClaw not found.${NC}"
  echo ""
  echo "  Install OpenClaw first: $(link 'https://openclaw.ai')"
  echo ""
  exit 1
fi

echo -e "${GREEN}✓ OpenClaw found${NC}"

# Create skills directory and download skill file
mkdir -p "$SKILLS_DIR"

if [ -f "${SKILLS_DIR}/SKILL.md" ]; then
  echo "  Updating skill..."
else
  echo "  Downloading skill..."
fi

curl -fsSL "${SKILL_RAW}/SKILL.md" -o "${SKILLS_DIR}/SKILL.md"

echo -e "${GREEN}✓ Skill installed to ${SKILLS_DIR}${NC}"

# Create workspace directory
if [ ! -d "$DISPATCH_DIR" ]; then
  mkdir -p "$DISPATCH_DIR"
  echo -e "${GREEN}✓ Created ${DISPATCH_DIR}${NC}"
else
  echo -e "${GREEN}✓ ${DISPATCH_DIR} already exists${NC}"
fi

# Create ledger files if they don't exist
for ledger in "dispatch-pending.md" "dispatch-inbound.md"; do
  LEDGER_FILE="${DISPATCH_DIR}/${ledger}"
  if [ ! -f "$LEDGER_FILE" ]; then
    touch "$LEDGER_FILE"
    echo -e "${GREEN}✓ Created ${LEDGER_FILE}${NC}"
  fi
done

# Create dispatchconfig.yml if it doesn't exist
CONFIG_FILE="${DISPATCH_DIR}/dispatchconfig.yml"
if [ ! -f "$CONFIG_FILE" ]; then
  echo ""
  echo "  Add a circle key from ${BOLD}$(link 'https://dispatch.peepsapp.ai' 'dispatch.peepsapp.ai')${NC} → Settings."
  echo "  A valid key is 64 lowercase hex characters. Press Enter to skip for now."
  echo ""
  read -r -p "  Circle key, or Enter to skip: " FIRST_KEY

  CIRCLE_KEYS=()
  CIRCLE_LABELS=()

  if [ -n "$FIRST_KEY" ]; then
    KEY="$FIRST_KEY"
    while true; do
      read -r -p "  Label for this circle (e.g. hk-network), or Enter to skip: " LABEL
      CIRCLE_KEYS+=("$KEY")
      CIRCLE_LABELS+=("$LABEL")
      echo ""
      echo "  1) Add another circle"
      echo "  2) Done"
      read -r -p "  Choice [1-2, default 2]: " CIRCLE_MENU
      CIRCLE_MENU=${CIRCLE_MENU:-2}
      if [ "$CIRCLE_MENU" = "1" ]; then
        read -r -p "  Circle key: " KEY
        if [ -z "$KEY" ]; then
          echo -e "${YELLOW}  Empty key — finishing.${NC}"
          break
        fi
      else
        break
      fi
    done
  fi

  {
    if [ ${#CIRCLE_KEYS[@]} -eq 0 ]; then
      echo "circles: []"
    else
      echo "circles:"
      i=0
      for KEY in "${CIRCLE_KEYS[@]}"; do
        ESC_KEY=$(printf '%s' "$KEY" | sed "s/'/''/g")
        echo "  - key: '${ESC_KEY}'"
        LABEL="${CIRCLE_LABELS[$i]}"
        if [ -n "$LABEL" ]; then
          ESC_LABEL=$(printf '%s' "$LABEL" | sed "s/'/''/g")
          echo "    label: '${ESC_LABEL}'"
        fi
        i=$((i + 1))
      done
    fi
  } > "$CONFIG_FILE"

  echo -e "${GREEN}✓ Created ${CONFIG_FILE}${NC}"
  if [ ${#CIRCLE_KEYS[@]} -eq 0 ]; then
    echo -e "${YELLOW}  No key added — edit ${CONFIG_FILE} to add one later.${NC}"
  fi
else
  echo -e "${GREEN}✓ ${CONFIG_FILE} already exists${NC}"
fi

echo ""
echo "  ──────────────────────────────────────────"
echo -e "  ${BOLD}Register for Dispatch:${NC}"
echo ""
echo "  To activate Dispatch, register your account at:"
echo ""
echo "    $(link 'https://dispatch.peepsapp.ai')"
echo ""
echo "  ──────────────────────────────────────────"
echo -e "  ${GREEN}All done.${NC} Try it:"
echo ""
echo '  "Search my circle — who knows a good architect in Singapore?"'
echo '  "Ask my network if anyone can help with fundraising in London."'
echo '  "Check if there are any new answers to my open questions."'
echo ""
echo "  Sign in and manage circles: $(link 'https://dispatch.peepsapp.ai')"
echo "  Source: $(link "$SKILL_WEB" "$SKILL_REPO")"
echo ""
