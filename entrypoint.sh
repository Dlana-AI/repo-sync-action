#!/bin/sh -l

set -e  # Stop execution if any command fails
set -u  # Treat unset variables as an error

echo "[+] Starting Repository Sync Action"

# Parse inputs
DESTINATION_REPO="${1}"  # Format: username/repository
TARGET_BRANCH="${2}"
SSH_PRIVATE_KEY="${3}"
GITHUB_TOKEN="${4}"  # GitHub token for private repos

# Verify GITHUB_TOKEN
if [ -z "${GITHUB_TOKEN}" ]; then
    echo "::error:: GitHub token is required for cloning private repositories"
    exit 1
fi

# Setup Git configuration
git config --global user.name "github-actions[bot]"
git config --global user.email "github-actions[bot]@users.noreply.github.com"

# Setup SSH authentication for destination repo
echo "[+] Setting up SSH authentication"
mkdir -p "$HOME/.ssh"
echo "$SSH_PRIVATE_KEY" > "$HOME/.ssh/id_rsa"
chmod 600 "$HOME/.ssh/id_rsa"

# Add GitHub to known hosts
ssh-keyscan -H github.com >> "$HOME/.ssh/known_hosts"

# Test SSH connection
echo "[+] Testing SSH connection"
if ! ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "::error:: SSH authentication failed"
    exit 1
fi

# Create temporary directory
TMP_DIR=$(mktemp -d)
echo "[+] Working directory: $TMP_DIR"

# Get current repository name from GitHub environment
SOURCE_REPO="${GITHUB_REPOSITORY:-$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1/')}"

# Setup repository URLs (HTTPS for source using token, SSH for destination)
SOURCE_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${SOURCE_REPO}.git"
DEST_URL="git@github.com:${DESTINATION_REPO}.git"

# Clone source repository
echo "[+] Cloning source repository: $SOURCE_REPO"
git clone --mirror "$SOURCE_URL" "$TMP_DIR/source"
cd "$TMP_DIR/source"

# Push to destination
echo "[+] Pushing to destination repository: $DESTINATION_REPO"
git push --mirror "$DEST_URL"

# Cleanup
rm -rf "$TMP_DIR"
echo "[+] Repository sync completed successfully"


# 	git clone --depth 1 "$GIT_CMD_REPOSITORY" "$CLONE_DIR"
# 	else
# 		echo "::error:: Could not clone repository or branch does not exist"
# 		exit 1
# 	fi

# # Copy all contents from source repository
# echo "[+] Copying repository contents"
# rsync -av --delete --exclude=".git" "$SOURCE_REPOSITORY"/ "$CLONE_DIR"/

# cd "$CLONE_DIR"

# echo "[+] Git status before commit:"
# git status

# git add .

# # Check if there are changes before committing
# if git diff-index --quiet HEAD; then
# 	echo "[+] No changes detected, skipping commit."
# else
# 	echo "[+] Committing changes"
# 	git commit -m "$COMMIT_MESSAGE"
# 	git push "$GIT_CMD_REPOSITORY" "$TARGET_BRANCH"
# fi

# echo "[+] Git push completed successfully."
