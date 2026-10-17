# Loads repos/NAME.sh for bin/novice and bin/review-pr and checks that it sets everything they use.
# Sets tower (this repository's root) and repo_name, plus whatever the settings file sets.

tower=$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/.." && pwd)

load_settings() {
	repo_name=${1:-}
	local file=$tower/repos/$repo_name.sh var
	if ! [[ $repo_name =~ ^[a-z0-9-]+$ ]] || [ ! -f "$file" ]; then
		echo "no settings for '$repo_name'; repos: $(cd "$tower/repos" && ls -- *.sh | sed 's/\.sh$//' | tr '\n' ' ')" >&2
		exit 1
	fi
	# shellcheck source=/dev/null
	. "$file"
	for var in repo clone state setup check allowed sandbox_ro flagged safety_code public; do
		declare -p "$var" > /dev/null 2>&1 || { echo "$file doesn't set $var" >&2; exit 1; }
	done
}
