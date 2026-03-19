#!/usr/bin/env bash
set -e

# Updates the dynamic links pointing to the latest build.
# Makes use of the Rebrandly API to do this.
# Delete and re-create the link since editing is unavailable on certain plans.

# REBRANDLY_API_KEY must be specified as an environment variable.
# For GitHub actions usage it will be stored in the repository's secrets.
if test -z "$REBRANDLY_API_KEY"; then
  echo "Error: REBRANDLY_API_KEY must be set as an environment variable." >&2
  exit 1
fi

# curl and jq must be installed for this script to work.
if ! curl --version &>/dev/null; then
  echo "Error: This script requires curl to be installed." >&2
  exit 1
fi
if ! jq --version &>/dev/null; then
  echo "Error: This script requires jq to be installed." >&2
  exit 1
fi

# New version to update links to must be passed as the first argument.
NEW_VERSION="$1"
if test -z "$NEW_VERSION"; then
  echo "Usage: $(basename "$0") <new-version>" >&2
  exit 1
fi

# Change these if you are reusing this script for your own links.
WORKSPACE_ID="617c32c66fb04d228b2fd3a5a6d93362"
DOMAIN="go.dmassey.net"
if echo "$NEW_VERSION" | grep -q -- "-rc"; then
  echo "Using prerelease (rc) slugs..."
  SLUG_X64="qemux64rc"
  SLUG_A64="qemua64rc"
else
  echo "Using standard release slugs..."
  SLUG_X64="qemux64"
  SLUG_A64="qemua64"
fi
DEST_X64="https://github.com/DanielMYT/qemu-appimage/releases/download/$NEW_VERSION/qemu-$NEW_VERSION-x86_64.AppImage"
DEST_A64="https://github.com/DanielMYT/qemu-appimage/releases/download/$NEW_VERSION/qemu-$NEW_VERSION-aarch64.AppImage"

# NOTE: A sleep of 3 seconds is done between API operations.
# This is to prevent possible rate-limiting.

# Fetch the IDs of the existing links.
echo "Fetching IDs of existing links..."
sleep 3
ID_X64="$(curl -sf "https://api.rebrandly.com/v1/links" -H "apikey: $REBRANDLY_API_KEY" -H "workspace: $WORKSPACE_ID" -H "Content-Type: application/json" | jq -r --arg slug "$SLUG_X64" 'map(select(.slashtag == $slug)) | .[0].id // empty')"
sleep 3
ID_A64="$(curl -sf "https://api.rebrandly.com/v1/links" -H "apikey: $REBRANDLY_API_KEY" -H "workspace: $WORKSPACE_ID" -H "Content-Type: application/json" | jq -r --arg slug "$SLUG_A64" 'map(select(.slashtag == $slug)) | .[0].id // empty')"
if test -z "$ID_X64" || test -z "$ID_A64"; then
  echo "Error: Failed to find link ID for '$SLUG_X64' and/or '$SLUG_A64'."
  exit 1
fi

# Delete and re-create x86_64 link.
echo "Deleting and re-creating x86_64 link..."
sleep 3
curl -fX DELETE "https://api.rebrandly.com/v1/links/$ID_X64" -H "apikey: $REBRANDLY_API_KEY" -H "workspace: $WORKSPACE_ID" -H "Content-Type: application/json" >/dev/null
sleep 3
curl -fX POST "https://api.rebrandly.com/v1/links" -H "apikey: $REBRANDLY_API_KEY" -H "workspace: $WORKSPACE_ID" -H "Content-Type: application/json" -d "{\"slashtag\":\"$SLUG_X64\",\"destination\":\"$DEST_X64\",\"domain\":{\"fullName\":\"$DOMAIN\"}}" >/dev/null

# Delete and re-create aarch64 link.
echo "Deleting and re-creating aarch64 link..."
sleep 3
curl -fX DELETE "https://api.rebrandly.com/v1/links/$ID_A64" -H "apikey: $REBRANDLY_API_KEY" -H "workspace: $WORKSPACE_ID" -H "Content-Type: application/json" >/dev/null
sleep 3
curl -fX POST "https://api.rebrandly.com/v1/links" -H "apikey: $REBRANDLY_API_KEY" -H "workspace: $WORKSPACE_ID" -H "Content-Type: application/json" -d "{\"slashtag\":\"$SLUG_A64\",\"destination\":\"$DEST_A64\",\"domain\":{\"fullName\":\"$DOMAIN\"}}" >/dev/null

# Finishing message.
echo "All done! Links have been updated successfully."
