#!/usr/bin/env bash
# Shared helpers for the bootstrap/install-*.sh scripts. Source, don't execute.

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

log() {
  printf '==> %s\n' "$*" >&2
}

require_ubuntu() {
  [[ "$(uname -s)" == "Linux" ]] || die "this script targets Ubuntu; on macOS use Homebrew"
  [[ -r /etc/os-release ]] || die "/etc/os-release not found; cannot confirm Ubuntu"
  local id
  # shellcheck source=/dev/null
  id="$(. /etc/os-release && printf '%s' "${ID:-}")"
  [[ "$id" == "ubuntu" ]] || die "expected Ubuntu, found '${id:-unknown}'"
  command -v sudo >/dev/null || die "sudo is required"
}

# Prints the release-asset architecture name: x86_64 or arm64.
detect_arch() {
  local machine
  machine="$(uname -m)"
  case "$machine" in
    x86_64 | amd64) printf 'x86_64' ;;
    aarch64 | arm64) printf 'arm64' ;;
    *) die "unsupported architecture: $machine" ;;
  esac
}

# download_verified <url> <sha256> <dest>
download_verified() {
  local url="$1" sha="$2" dest="$3"
  log "downloading $url"
  curl -fsSL --retry 3 -o "$dest" "$url"
  printf '%s  %s\n' "$sha" "$dest" | sha256sum --check --quiet - \
    || die "checksum mismatch for $url"
}
