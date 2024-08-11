#!/bin/bash

# URL of the Launchpad mirror list
MIRROR_LIST="https://launchpad.net/ubuntu/+archivemirrors"

# Check if correct number of arguments are passed
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <architecture> <distribution> <repository>"
  exit 1
fi

# Set to the architecture, distribution, and repository you're looking for
ARCH=$1
DIST=$2
REPO=$3

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

