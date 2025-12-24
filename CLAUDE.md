# Signalforge PHP Builds

## Overview

This repository builds custom PHP Docker images with Signalforge extensions for ghcr.io/thesignalforge.

## Docker Images

### FPM Image (`Dockerfile.base`)
- Runs PHP-FPM daemon on port 9000
- Contains 3 extensions: signalforge_routing, signalforge_http, keyshare
- Tags: `php84`, `php8.4`, `latest`, `php85`, `php8.5`

### CLI Image (`Dockerfile.cli`)
- Based on FPM image, adds terminal extension
- Entrypoint is `php`, no daemon
- Tags: `php-cli`, `php8.4-cli`, `php8.5-cli`

## Extensions

Extensions are in separate public repos under `thesignalforge` org:

| Repo | Configure Option | Extension Name | Notes |
|------|------------------|----------------|-------|
| thesignalforge/router | `--enable-signalforge_routing` | signalforge_routing.so | Routing |
| thesignalforge/request | `--enable-signalforge_http` | signalforge_http.so | HTTP handling |
| thesignalforge/keyshare | `--enable-keyshare` | keyshare.so | Key sharing |
| thesignalforge/dotenv | `--enable-signalforge_dotenv` | signalforge_dotenv.so | Env file loading (requires libsodium) |
| thesignalforge/terminal | `--enable-terminal` | terminal.so | CLI only |

**Important**: Extension names in config.m4 don't match repo names. Always check `PHP_ARG_ENABLE` in config.m4.

## Build Process

### Local Build
```bash
# Create build context
mkdir -p build/images && cp images/*.ini images/*.conf build/images/

# Clone extensions
git clone --depth 1 https://github.com/thesignalforge/router.git ext/router
git clone --depth 1 https://github.com/thesignalforge/request.git ext/request
git clone --depth 1 https://github.com/thesignalforge/keyshare.git ext/keyshare
git clone --depth 1 https://github.com/thesignalforge/dotenv.git ext/dotenv
git clone --depth 1 https://github.com/thesignalforge/terminal.git ext/terminal

# Build FPM image
docker build --build-arg PHP_BRANCH=PHP-8.4 -f images/Dockerfile.base -t signalforge:php84 .

# Build CLI image
docker build --build-arg BASE_IMAGE=signalforge:php84 -f images/Dockerfile.cli -t signalforge:php-cli .
```

### Push to Registry
```bash
echo "TOKEN" | docker login ghcr.io -u USERNAME --password-stdin

# Tag and push FPM
docker tag signalforge:php84 ghcr.io/thesignalforge/signalforge:php84
docker tag signalforge:php84 ghcr.io/thesignalforge/signalforge:php8.4
docker tag signalforge:php84 ghcr.io/thesignalforge/signalforge:latest
docker push ghcr.io/thesignalforge/signalforge:php84
docker push ghcr.io/thesignalforge/signalforge:php8.4
docker push ghcr.io/thesignalforge/signalforge:latest

# Tag and push CLI
docker tag signalforge:php-cli ghcr.io/thesignalforge/signalforge:php-cli
docker tag signalforge:php-cli ghcr.io/thesignalforge/signalforge:php8.4-cli
docker push ghcr.io/thesignalforge/signalforge:php-cli
docker push ghcr.io/thesignalforge/signalforge:php8.4-cli

docker logout ghcr.io
```

## GitHub Actions

Workflow: `.github/workflows/build-images.yml`
- Trigger: `workflow_dispatch` (manual)
- Runner: self-hosted with label `signalforge`
- Registry: ghcr.io/thesignalforge/signalforge

## Git Conventions

- Author: `signalforger <signalforger@workplace.hr>`
- No Claude references in commits
- Organization: `thesignalforge` (not thesignalforger)

## Directory Structure

```
.
├── images/
│   ├── Dockerfile.base    # FPM image
│   ├── Dockerfile.cli     # CLI image (extends base)
│   ├── php.ini            # PHP configuration
│   ├── php-fpm.conf       # FPM configuration
│   └── nginx.conf         # Nginx config (reference)
├── .github/workflows/
│   └── build-images.yml   # CI/CD workflow
├── ext/                   # (gitignored) cloned extensions for local builds
└── build/                 # (gitignored) build context for local builds
```

## PHP Configuration

Extensions are loaded in `images/php.ini`:
```ini
extension=signalforge_routing.so
extension=signalforge_http.so
extension=signalforge_dotenv.so
extension=keyshare.so
```

CLI image appends `extension=terminal.so` during build.

## Supported PHP Versions

- PHP 8.4 (default, stable)
- PHP 8.5 (development branch)

Set via `PHP_BRANCH` build arg: `PHP-8.4` or `PHP-8.5`
