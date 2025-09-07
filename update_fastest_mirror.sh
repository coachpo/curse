#!/bin/bash

# URL of the Launchpad mirror list
MIRROR_LIST="https://launchpad.net/ubuntu/+archivemirrors"

# Get current Ubuntu distribution
DIST=$(lsb_release -cs)
ARCH=$(dpkg --print-architecture)

echo "Detected Ubuntu distribution: $DIST"
echo "Detected architecture: $ARCH"
echo ""

# Prompt for repository if not provided as an argument
if [ -z "$1" ]; then
  read -p "Enter the repository (main, restricted, universe, multiverse) [main]: " REPO
  REPO=${REPO:-main}
else
  REPO=$1
fi

echo "Testing mirrors for repository: $REPO"
echo ""

# Function to test mirror speed
test_mirror_speed() {
    local url=$1
    local start_time=$(date +%s.%N)
    
    if curl --connect-timeout 5 -m 10 -s --head "$url/dists/$DIST/$REPO/binary-$ARCH/" | head -n 1 | grep -q "HTTP/1.[01] [23].."; then
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc -l)
        echo "$duration $url"
        return 0
    fi
    return 1
}

# Export function for parallel execution
export -f test_mirror_speed
export DIST ARCH REPO

echo "Testing mirror speeds..."
echo ""

# Get mirror list and test speeds in parallel
mirrorList=()
while IFS= read -r url; do
  mirrorList+=( "$url" )
done < <(curl -s "$MIRROR_LIST" | grep -Po 'http://.*(?=">http</a>)')

# Test mirrors and collect results
results=()
for url in "${mirrorList[@]}"; do
  (
    result=$(test_mirror_speed "$url")
    if [ $? -eq 0 ]; then
        echo "$result"
    fi
  ) &
done

wait

echo ""
echo "Collecting results..."

# Get results and sort by speed
results=($(jobs -p | xargs -I {} wait {} 2>/dev/null || true))
if [ ${#results[@]} -eq 0 ]; then
    echo "No working mirrors found. Testing mirrors again..."
    
    # Fallback: test mirrors sequentially and collect results
    results=()
    for url in "${mirrorList[@]}"; do
        result=$(test_mirror_speed "$url" 2>/dev/null)
        if [ $? -eq 0 ]; then
            results+=("$result")
        fi
    done
fi

if [ ${#results[@]} -eq 0 ]; then
    echo "ERROR: No working mirrors found!"
    exit 1
fi

# Sort results by speed (fastest first)
IFS=$'\n' sorted_results=($(sort -n <<<"${results[*]}"))
unset IFS

# Get the fastest mirror
fastest_mirror=$(echo "${sorted_results[0]}" | cut -d' ' -f2-)
fastest_time=$(echo "${sorted_results[0]}" | cut -d' ' -f1)

echo "Fastest mirror found: $fastest_mirror (${fastest_time}s)"
echo ""

# Backup current sources.list
echo "Backing up current sources.list..."
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d_%H%M%S)

# Update sources.list with the fastest mirror
echo "Updating sources.list with fastest mirror..."

# Create new sources.list content
cat > /tmp/sources.list.new << EOF
# Updated by find_fastest_source.sh on $(date)
# Fastest mirror: $fastest_mirror

deb $fastest_mirror $DIST main restricted universe multiverse
deb $fastest_mirror $DIST-updates main restricted universe multiverse
deb $fastest_mirror $DIST-backports main restricted universe multiverse
deb $fastest_mirror $DIST-security main restricted universe multiverse

# Uncomment the following lines if you need source packages
# deb-src $fastest_mirror $DIST main restricted universe multiverse
# deb-src $fastest_mirror $DIST-updates main restricted universe multiverse
# deb-src $fastest_mirror $DIST-backports main restricted universe multiverse
# deb-src $fastest_mirror $DIST-security main restricted universe multiverse
EOF

# Replace sources.list
sudo mv /tmp/sources.list.new /etc/apt/sources.list

echo "Sources.list updated successfully!"
echo ""

# Update package lists
echo "Updating package lists with new mirror..."
sudo apt update

if [ $? -eq 0 ]; then
    echo ""
    echo "SUCCESS: System updated to use fastest mirror!"
    echo "Fastest mirror: $fastest_mirror"
    echo "Backup saved as: /etc/apt/sources.list.backup.$(date +%Y%m%d_%H%M%S)"
    echo ""
    echo "You can restore the original sources.list with:"
    echo "sudo cp /etc/apt/sources.list.backup.* /etc/apt/sources.list"
else
    echo ""
    echo "ERROR: Failed to update package lists!"
    echo "Restoring original sources.list..."
    sudo cp /etc/apt/sources.list.backup.* /etc/apt/sources.list
    echo "Original sources.list restored."
    exit 1
fi
