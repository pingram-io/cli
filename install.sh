#!/usr/bin/env bash
# Pingram CLI installer
#
# Usage:
# curl -fsSL https://raw.githubusercontent.com/pingram-io/cli/main/install.sh | bash
# curl -fsSL https://raw.githubusercontent.com/pingram-io/cli/main/install.sh | bash -s 0.1.0
#
# Environment variables:
# PINGRAM_INSTALL - Custom install directory (default: ~/.pingram)
# GITHUB_BASE     - Custom GitHub base URL (default: https://github.com)

main() {
  set -euo pipefail

  Color_Off='' Red='' Green='' Dim='' Bold='' Blue='' Yellow=''

  if [[ -t 1 ]]; then
    Color_Off='\033[0m'
    Red='\033[0;31m'
    Green='\033[0;32m'
    Yellow='\033[0;33m'
    Dim='\033[0;2m'
    Bold='\033[1m'
    Blue='\033[0;34m'
  fi

  error() {
    printf "%b\n" "${Red}error${Color_Off}: $*" >&2
    exit 1
  }

  warn() {
    printf "%b\n" "${Yellow}warn${Color_Off}: $*" >&2
  }

  info() {
    printf "%b\n" "${Dim}$*${Color_Off}"
  }

  success() {
    printf "%b\n" "${Green}$*${Color_Off}"
  }

  bold() {
    printf "%b\n" "${Bold}$*${Color_Off}"
  }

  tildify() {
    if [[ $1 == "$HOME"/* ]]; then
      echo "~${1#"$HOME"}"
    else
      echo "$1"
    fi
  }

  command -v curl >/dev/null 2>&1 || error "curl is required but not found. Install it and try again."
  command -v tar >/dev/null 2>&1 || error "tar is required but not found. Install it and try again."

  platform=$(uname -ms)

  case $platform in
    'Darwin x86_64') target=darwin-x64 ;;
    'Darwin arm64') target=darwin-arm64 ;;
    'Linux aarch64') target=linux-arm64 ;;
    'Linux x86_64') target=linux-x64 ;;
    'Linux arm64') target=linux-arm64 ;;
    *)
      error "Unsupported platform: ${platform}.

 Pingram CLI supports:
 - macOS (Apple Silicon / Intel)
 - Linux (x64 / arm64)

 For Windows, run this in PowerShell:
 irm https://raw.githubusercontent.com/pingram-io/cli/main/install.ps1 | iex"
      ;;
  esac

  if [[ $target == "darwin-x64" ]]; then
    if [[ $(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0) == "1" ]]; then
      target=darwin-arm64
      info " Rosetta 2 detected — installing native arm64 binary"
    fi
  fi

  if [[ $target == linux-* ]]; then
    if ldd --version 2>&1 | grep -qi musl 2>/dev/null; then
      error "Alpine Linux (musl) is not currently supported.

 The compiled binary requires glibc. Use one of these alternatives:
 - npm install -g pingram-cli
 - Run in a glibc-based container (e.g., ubuntu, debian)"
    fi
  fi

  GITHUB_BASE=${GITHUB_BASE:-"https://github.com"}

  case "$GITHUB_BASE" in
    https://*) ;;
    *) error "GITHUB_BASE must start with https:// (got: ${GITHUB_BASE})" ;;
  esac

  REPO="${GITHUB_BASE}/pingram-io/cli"
  TAG_PREFIX="pingram-cli-v"
  VERSION=${1:-}

  if [[ -n $VERSION ]]; then
    VERSION="${VERSION#v}"
    if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
      error "Invalid version format: ${VERSION}

 Expected: semantic version like 0.1.0 or 1.2.3-beta.1
 Usage: curl -fsSL .../install.sh | bash -s 0.1.0"
    fi
    tag="${TAG_PREFIX}${VERSION}"
    url="${REPO}/releases/download/${tag}/pingram-${target}.tar.gz"
  else
    tag=$(
      curl -fsSL "https://api.github.com/repos/pingram-io/cli/releases?per_page=100" |
        grep -o '"tag_name": "pingram-cli-v[^"]*"' |
        head -1 |
        sed 's/"tag_name": "//;s/"//'
    )
    if [[ -z $tag ]]; then
      error "No Pingram CLI release found. Install via npm instead: npm install -g pingram-cli"
    fi
    url="${REPO}/releases/download/${tag}/pingram-${target}.tar.gz"
  fi

  install_dir="${PINGRAM_INSTALL:-$HOME/.pingram}"
  bin_dir="${install_dir}/bin"
  exe="${bin_dir}/pingram"

  mkdir -p "$bin_dir" || error "Failed to create install directory: ${bin_dir}"

  echo ""
  bold " Installing Pingram CLI..."
  echo ""

  tmpdir=$(mktemp -d) || error "Failed to create temporary directory"
  trap 'rm -rf "$tmpdir"' EXIT INT TERM

  tmpfile="${tmpdir}/pingram.tar.gz"

  info " Downloading from ${url}"
  echo ""

  curl --fail --location --progress-bar --output "$tmpfile" "$url" ||
    error "Download failed.

 Possible causes:
 - No internet connection
 - The version does not exist: ${VERSION:-latest}
 - GitHub is unreachable

 URL: ${url}"

  tar -xzf "$tmpfile" -C "$bin_dir" ||
    error "Failed to extract archive. The download may be corrupted — try again."

  chmod +x "$exe" || error "Failed to make binary executable"

  if [[ $(uname -s) == "Darwin" ]]; then
    xattr -d com.apple.quarantine "$exe" 2>/dev/null || true
  fi

  installed_version=$("$exe" --version 2>/dev/null || echo "unknown")

  echo ""
  success " Pingram CLI ${installed_version} installed successfully!"
  echo ""
  info " Binary: $(tildify "$exe")"

  if command -v pingram >/dev/null 2>&1; then
    existing=$(command -v pingram)
    if [[ "$existing" == "$exe" ]]; then
      echo ""
      bold " Run ${Blue}pingram login${Color_Off}${Bold} to get started${Color_Off}"
      echo ""
      exit 0
    else
      warn "another 'pingram' was found at ${existing}"
      info " The new installation at $(tildify "$exe") may be shadowed."
    fi
  fi

  if echo "$PATH" | tr ':' '\n' | grep -qxF "${bin_dir}" 2>/dev/null; then
    echo ""
    bold " Run ${Blue}pingram login${Color_Off}${Bold} to get started${Color_Off}"
    echo ""
    exit 0
  fi

  shell_name=$(basename "${SHELL:-}")
  config=""
  shell_line=""

  if [[ $bin_dir == "$HOME"/* ]]; then
    shell_bin_dir="\$HOME${bin_dir#"$HOME"}"
  else
    shell_bin_dir="$bin_dir"
  fi

  case $shell_name in
    zsh)
      config="${ZDOTDIR:-$HOME}/.zshrc"
      shell_line="export PATH=\"${shell_bin_dir}:\$PATH\""
      ;;
    bash)
      if [[ $(uname -s) == "Darwin" ]]; then
        if [[ -f "$HOME/.bash_profile" ]]; then
          config="$HOME/.bash_profile"
        elif [[ -f "$HOME/.bashrc" ]]; then
          config="$HOME/.bashrc"
        else
          config="$HOME/.bash_profile"
        fi
      else
        if [[ -f "$HOME/.bashrc" ]]; then
          config="$HOME/.bashrc"
        elif [[ -f "$HOME/.bash_profile" ]]; then
          config="$HOME/.bash_profile"
        else
          config="$HOME/.bashrc"
        fi
      fi
      shell_line="export PATH=\"${shell_bin_dir}:\$PATH\""
      ;;
    fish)
      config="${XDG_CONFIG_HOME:-$HOME/.config}/fish/conf.d/pingram.fish"
      mkdir -p "$(dirname "$config")"
      shell_line="fish_add_path ${shell_bin_dir}"
      ;;
  esac

  if [[ -n $config ]]; then
    if [[ -f "$config" ]] && (grep -qF "$(tildify "$bin_dir")" "$config" 2>/dev/null || grep -qF "$bin_dir" "$config" 2>/dev/null); then
      info " PATH already configured in $(tildify "$config")"
    elif [[ -w "${config%/*}" ]] || [[ -w "$config" ]]; then
      {
        echo ""
        echo "# Pingram CLI"
        echo "$shell_line"
      } >>"$config"
      info " Added $(tildify "$bin_dir") to \$PATH in $(tildify "$config")"
      echo ""
      info " To start using Pingram CLI, run:"
      echo ""
      bold " source $(tildify "$config")"
      bold " pingram login"
    else
      echo ""
      info " Manually add to your shell config:"
      echo ""
      bold " ${shell_line}"
    fi
  else
    echo ""
    info " Add to your shell config:"
    echo ""
    bold " export PATH=\"${shell_bin_dir}:\$PATH\""
  fi

  echo ""
  info " Next steps:"
  echo ""
  bold " pingram login"
  bold " pingram --help"
  echo ""
}

main "$@"
