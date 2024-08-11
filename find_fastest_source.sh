#!/bin/bash

# URL of the Launchpad mirror list
MIRROR_LIST="https://launchpad.net/ubuntu/+archivemirrors"

# Prompt for architecture if not provided as an argument
if [ -z "$1" ]; then
  read -p "Enter the architecture (e.g., amd64, i386, arm64, armhf, armel, powerpc): " ARCH
else
  ARCH=$1
fi

# Prompt for distribution if not provided as an argument
if [ -z "$2" ]; then
  read -p "Enter the Ubuntu distribution (e.g., precise, saucy, trusty, focal, jammy): " DIST
else
  DIST=$2
fi

# Prompt for repository if not provided as an argument
if [ -z "$3" ]; then
  read -p "Enter the repository (main, restricted, universe, multiverse): " REPO
else
  REPO=$3
fi

mirrorList=()
# Retrieve the Launchpad mirror list and extract HTTP mirrors
while IFS= read -r url; do
  mirrorList+=( "$url" )
done < <(curl -s "$MIRROR_LIST" | grep -Po 'http://.*(?=">http</a>)')

# Check each mirror for the specified architecture, distribution, and repository
for url in "${mirrorList[@]}"; do
  (
    echo "Processing $url..."
    # Check if the URL exists and returns a status code 2xx or 3xx
    if curl --connect-timeout 5 -m 5 -s --head "$url/dists/$DIST/$REPO/binary-$ARCH/" | head -n 1 | grep -q "HTTP/1.[01] [23].."; then
        echo "FOUND: $url"
    fi
  ) &
done

wait

echo "All done!"
