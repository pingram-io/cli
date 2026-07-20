# Pingram CLI

Official command-line interface for [Pingram](https://pingram.io).

Manage domains, send messages, inspect logs, and more from your terminal.

## Install

### npm

Requires Node.js 18+.

```bash
npm install -g pingram-cli
```

### cURL (macOS / Linux)

```bash
curl -fsSL https://raw.githubusercontent.com/pingram-io/cli/main/install.sh | bash
```

Pin a version:

```bash
curl -fsSL https://raw.githubusercontent.com/pingram-io/cli/main/install.sh | bash -s 1.0.16
```

### PowerShell (Windows)

```powershell
irm https://raw.githubusercontent.com/pingram-io/cli/main/install.ps1 | iex
```

Pin a version:

```powershell
$env:PINGRAM_VERSION = '1.0.16'; irm https://raw.githubusercontent.com/pingram-io/cli/main/install.ps1 | iex
```

### Homebrew

Coming soon.

## Quick start

```bash
pingram login
pingram domains list
pingram --help
```

Get your API key and region (`us`, `eu`, or `ca`) from the **API Keys** page in the [Pingram dashboard](https://app.pingram.io).

## Docs

Full command reference: [pingram.io/docs/reference/cli](https://www.pingram.io/docs/reference/cli)

## Releases

Standalone binaries are published on the [Releases](https://github.com/pingram-io/cli/releases) page.

| Asset | Platform |
| --- | --- |
| `pingram-windows-x64.zip` | Windows x64 |
| `pingram-darwin-arm64.tar.gz` | macOS Apple Silicon |
| `pingram-darwin-x64.tar.gz` | macOS Intel |
| `pingram-linux-x64.tar.gz` | Linux x64 |
| `pingram-linux-arm64.tar.gz` | Linux arm64 |

## Source

This repository hosts install scripts and release binaries for the Pingram CLI.
