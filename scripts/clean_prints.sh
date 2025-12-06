#!/bin/bash

# Remove all print() statements from Dart files, including multi-line ones
# This script processes each file and removes complete print statements

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🧹 Removing all print() statements...${NC}\n"

# Counter
MODIFIED_FILES=0

# Find all .dart files in lib/
find lib/ -name "*.dart" | while read -r file; do
  # Create a temporary file
  TMP_FILE=$(mktemp)
  
  # Use perl to remove print statements (handles multi-line)
  perl -0pe 's/print\s*\([^;]*?\);(\n)?//gs' "$file" > "$TMP_FILE"
  
  # Check if file changed
  if ! cmp -s "$file" "$TMP_FILE"; then
    mv "$TMP_FILE" "$file"
    echo -e "${GREEN}✅ Cleaned:${NC} $file"
    ((MODIFIED_FILES++))
  else
    rm "$TMP_FILE"
  fi
done

echo -e "\n${GREEN}✨ Done! Modified $MODIFIED_FILES files${NC}\n"

# Verify
REMAINING=$(grep -rn "print(" lib/ 2>/dev/null | grep -v "// print" | grep -v "printError" | wc -l | xargs)

if [ "$REMAINING" -eq 0 ]; then
  echo -e "${GREEN}🎉 All print() statements removed!${NC}"
else
  echo -e "${YELLOW}⚠️  Warning: $REMAINING potential print statements remain${NC}"
  echo -e "${YELLOW}   (may include false positives in strings/comments)${NC}"
fi
