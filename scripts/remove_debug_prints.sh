#!/bin/bash

# Lazzo - Debug Print Removal Script
# Purpose: Remove all print() statements from source code before merging to main
# Usage: ./scripts/remove_debug_prints.sh [--dry-run]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=true
fi

echo -e "${BLUE}🔍 Lazzo Debug Print Cleaner${NC}"
echo "================================"
echo ""

# Count total prints before
TOTAL_PRINTS=$(grep -rn "print(" lib/ 2>/dev/null | grep -v "// print" | grep -v "printError" | wc -l | xargs)

if [[ "$TOTAL_PRINTS" -eq 0 ]]; then
  echo -e "${GREEN}✅ No debug prints found! Codebase is clean.${NC}"
  exit 0
fi

echo -e "${YELLOW}Found $TOTAL_PRINTS print() statements${NC}"
echo ""

# Show files with prints
echo -e "${BLUE}Files containing prints:${NC}"
grep -rn "print(" lib/ 2>/dev/null | grep -v "// print" | grep -v "printError" | cut -d: -f1 | sort -u | while read file; do
  COUNT=$(grep -n "print(" "$file" | grep -v "// print" | grep -v "printError" | wc -l | xargs)
  echo "  📄 $file ($COUNT prints)"
done
echo ""

if [[ "$DRY_RUN" == true ]]; then
  echo -e "${YELLOW}🔬 DRY RUN MODE - No files will be modified${NC}"
  echo ""
  echo "Preview of prints to be removed:"
  grep -rn "print(" lib/ 2>/dev/null | grep -v "// print" | grep -v "printError" | head -20
  if [[ "$TOTAL_PRINTS" -gt 20 ]]; then
    echo "  ... and $((TOTAL_PRINTS - 20)) more"
  fi
  echo ""
  echo "Run without --dry-run to remove prints"
  exit 0
fi

# Confirm before proceeding
echo -e "${YELLOW}⚠️  This will remove all print() statements from lib/ folder${NC}"
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 1
fi

echo ""
echo -e "${BLUE}🧹 Removing debug prints...${NC}"

# Strategy: Comment out print lines instead of deleting to preserve git history
# Pattern matches common print formats:
# - print('...')
# - print("...")
# - print(variable)
# - print('[Feature] ...')

find lib/ -type f -name "*.dart" -exec sed -i '' \
  -e 's/^\([[:space:]]*\)print(\(.*\));$/\1\/\/ DEBUG REMOVED: print(\2);/g' \
  {} +

# Count remaining prints
REMAINING=$(grep -rn "print(" lib/ 2>/dev/null | grep -v "// print" | grep -v "printError" | grep -v "DEBUG REMOVED" | wc -l | xargs)

echo ""
if [[ "$REMAINING" -eq 0 ]]; then
  echo -e "${GREEN}✅ Success! All $TOTAL_PRINTS prints removed.${NC}"
  echo ""
  echo "Prints have been commented out to preserve git history:"
  echo "  // DEBUG REMOVED: print(...);"
  echo ""
  echo "Next steps:"
  echo "  1. Review changes: git diff lib/"
  echo "  2. Test the app: flutter run"
  echo "  3. Commit: git add -A && git commit -m 'chore: remove debug prints'"
else
  echo -e "${YELLOW}⚠️  Warning: $REMAINING prints still remain${NC}"
  echo ""
  echo "These prints might need manual review:"
  grep -rn "print(" lib/ 2>/dev/null | grep -v "// print" | grep -v "printError" | grep -v "DEBUG REMOVED"
  echo ""
  echo "Review these manually to determine if they should be kept or removed."
  exit 1
fi

# Show summary
echo ""
echo -e "${BLUE}📊 Summary:${NC}"
echo "  Total prints removed: $TOTAL_PRINTS"
echo "  Files modified: $(git diff --name-only lib/ | wc -l | xargs)"
echo ""
echo -e "${GREEN}Done! Run 'git diff' to review changes.${NC}"
