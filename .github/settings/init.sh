#!/usr/bin/env bash

if ! command -v tofu >/dev/null; then
	echo "OpenTofu not installed but required (for applying settings): https://opentofu.org"
	exit 1
fi

if ! command -v gh >/dev/null; then
	echo "GH CLI not installed but required (for authentication): https://cli.github.com"
	exit 1
fi

tofu fmt
tofu init
tofu validate
tofu apply

repository_name=$(grep -E 'repository_name\s+=' main.tf | cut -d '=' -f2 | xargs)
repository_owner=$(grep -E 'owner\s+=' providers.tf | cut -d '=' -f2 | xargs)

gh workflow disable "Settings" --repo "${repository_owner}/${repository_name}"
