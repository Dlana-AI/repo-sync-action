#!/bin/sh -l

set -e  # Stop execution if any command fails
set -u  # Treat unset variables as an error

echo "[+] Starting GitHub Action"
SOURCE_REPOSITORY="${1}"
DESTINATION_GITHUB_USERNAME="${2}"
DESTINATION_REPOSITORY_NAME="${3}"
GITHUB_SERVER="${4}"
USER_EMAIL="${5}"
USER_NAME="${6}"
DESTINATION_REPOSITORY_USERNAME="${7}"
TARGET_BRANCH="${8}"
COMMIT_MESSAGE="${9}"
CREATE_TARGET_BRANCH_IF_NEEDED="${10}"

# Default username
if [ -z "$DESTINATION_REPOSITORY_USERNAME" ]; then
	DESTINATION_REPOSITORY_USERNAME="$DESTINATION_GITHUB_USERNAME"
fi

if [ -z "$USER_NAME" ]; then
	USER_NAME="$DESTINATION_GITHUB_USERNAME"
fi

# Setup Git authentication (SSH or Token)
if [ -n "${SSH_DEPLOY_KEY:=}" ]; then
	echo "[+] Using SSH_DEPLOY_KEY"

	mkdir -p "$HOME/.ssh"
	DEPLOY_KEY_FILE="$HOME/.ssh/deploy_key"
	echo "${SSH_DEPLOY_KEY}" > "$DEPLOY_KEY_FILE"
	chmod 600 "$DEPLOY_KEY_FILE"

	SSH_KNOWN_HOSTS_FILE="$HOME/.ssh/known_hosts"
	ssh-keyscan -H "$GITHUB_SERVER" > "$SSH_KNOWN_HOSTS_FILE"

	export GIT_SSH_COMMAND="ssh -i "$DEPLOY_KEY_FILE" -o UserKnownHostsFile=$SSH_KNOWN_HOSTS_FILE"
	GIT_CMD_REPOSITORY="git@$GITHUB_SERVER:$DESTINATION_REPOSITORY_USERNAME/$DESTINATION_REPOSITORY_NAME.git"

elif [ -n "${API_TOKEN_GITHUB:=}" ]; then
	echo "[+] Using API_TOKEN_GITHUB"
	GIT_CMD_REPOSITORY="https://$DESTINATION_REPOSITORY_USERNAME:$API_TOKEN_GITHUB@$GITHUB_SERVER/$DESTINATION_REPOSITORY_USERNAME/$DESTINATION_REPOSITORY_NAME.git"
else
	echo "::error:: No authentication method provided (API_TOKEN_GITHUB or SSH_DEPLOY_KEY)"
	exit 1
fi

# Clone destination repository
CLONE_DIR=$(mktemp -d)
echo "[+] Cloning destination repository: $DESTINATION_REPOSITORY_NAME"

git config --global user.email "$USER_EMAIL"
git config --global user.name "$USER_NAME"

{
	git clone --depth 1 --branch "$TARGET_BRANCH" "$GIT_CMD_REPOSITORY" "$CLONE_DIR"
} || {
	if [ "$CREATE_TARGET_BRANCH_IF_NEEDED" = "true" ]; then
		git clone --depth 1 "$GIT_CMD_REPOSITORY" "$CLONE_DIR"
	else
		echo "::error:: Could not clone repository or branch does not exist"
		exit 1
	fi
}

# Copy all contents from source repository
echo "[+] Copying repository contents"
rsync -av --delete --exclude=".git" "$SOURCE_REPOSITORY"/ "$CLONE_DIR"/

cd "$CLONE_DIR"

echo "[+] Git status before commit:"
git status

git add .

# Check if there are changes before committing
if git diff-index --quiet HEAD; then
	echo "[+] No changes detected, skipping commit."
else
	echo "[+] Committing changes"
	git commit -m "$COMMIT_MESSAGE"
	git push "$GIT_CMD_REPOSITORY" "$TARGET_BRANCH"
fi

echo "[+] Git push completed successfully."
