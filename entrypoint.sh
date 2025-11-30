#!/bin/bash
set -e

# --- CONFIGURATION ---
LATEST_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name | sed 's/v//')
echo "Detected latest GitHub Runner version: ${LATEST_VERSION}"


# Extract Org name from URL (assumes https://github.com/my-org)
ORG_NAME=$(echo $REPO_URL | awk -F/ '{print $NF}')

# --- FUNCTIONS ---
get_token() {
    # Request a Registration Token for the Organization
    curl -s -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${GH_PAT}" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "https://api.github.com/orgs/${ORG_NAME}/actions/runners/registration-token" | jq -r .token
}

get_remove_token() {
    # Request a Removal Token (needed to deregister cleanly)
    curl -s -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${GH_PAT}" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "https://api.github.com/orgs/${ORG_NAME}/actions/runners/remove-token" | jq -r .token
}

cleanup() {
    echo "Caught SIGTERM/SIGINT. Deregistering runner..."
    REMOVE_TOKEN=$(get_remove_token)
    ./config.sh remove --token "${REMOVE_TOKEN}"
    exit 0
}

# --- MAIN ---
GH_RUNNER_VERSION="${LATEST_VERSION}"

# 1. Setup Trap for clean shutdown
trap 'cleanup' SIGTERM SIGINT

# 2. Prepare Directory
mkdir -p /actions-runner && cd /actions-runner

# 3. Download Runner (if missing)
if [ ! -f "actions-runner-linux-x64-${GH_RUNNER_VERSION}.tar.gz" ]; then
    echo "Downloading Runner v${GH_RUNNER_VERSION}..."
    curl -o actions-runner-linux-x64-${GH_RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${GH_RUNNER_VERSION}/actions-runner-linux-x64-${GH_RUNNER_VERSION}.tar.gz
    tar xzf ./actions-runner-linux-x64-${GH_RUNNER_VERSION}.tar.gz
fi

# 4. Get Registration Token
echo "Getting Registration Token..."
REG_TOKEN=$(get_token)

if [ "$REG_TOKEN" == "null" ] || [ -z "$REG_TOKEN" ]; then
    echo "Error: Failed to get token. Verify your GH_PAT and Org Permissions."
    exit 1
fi

# 5. Configure
export RUNNER_ALLOW_RUNASROOT="1"

./config.sh \
    --url "${REPO_URL}" \
    --token "${REG_TOKEN}" \
    --name "${RUNNER_NAME}-$(hostname)" \
    --work _work \
    --labels "self-hosted,vps,docker" \
    --unattended \
    --replace \
    --ephemeral 
    # Note: --ephemeral causes the runner to unregister itself after ONE job. 
    # If you want it to stay alive for many jobs, remove --ephemeral. 
    # But for Docker, --ephemeral is often cleaner (one container = one job).

# 6. Run
echo "Starting Runner..."
./run.sh & wait $!
