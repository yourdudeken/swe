#!/usr/bin/env bash
set -euo pipefail

installer_url="${OPENCODE_SWE_INSTALLER_URL:-https://raw.githubusercontent.com/yourdudeken/swe/main/scripts/install.sh}"
exec bash -c "$(curl --fail --location --silent --show-error "$installer_url")" -- --update
