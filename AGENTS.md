# Codex Sandbox AI Instructions

## Project Overview
This is a minimal Docker base image repository that packages the `@openai/codex` CLI into a lightweight, multi-platform container. The repo focuses on automation, versioning, and distribution rather than application development.

## Key Architecture Patterns

### Docker Build Strategy
- **Single-purpose image**: Only includes Node.js + Codex CLI, not a full dev environment
- **Multi-platform builds**: Always target `linux/amd64,linux/arm64` using buildx
- **Version-locked builds**: Use `--build-arg CODEX_VERSION=x.y.z` for reproducible images
- **Layer optimization**: Group apt commands, clean caches, use `--no-install-recommends`

### Automated Version Management
- **Version tracking**: `VERSION.md` contains current Codex CLI version (single line)
- **Update detection**: `update_docker.sh` queries npm registry via `npm view @openai/codex version`
- **PR automation**: Creates PRs when new versions detected with format "🚀 Bump Codex to vX.Y.Z"
- **Conditional builds**: Only builds if `docker manifest inspect` shows version doesn't exist

### CI/CD Workflows
- **Daily checks**: Scheduled at midnight UTC to check for new Codex versions
- **Manual triggers**: Push to main also triggers update check
- **Multi-stage process**: Build → Update VERSION.md → Create PR (if needed)
- **Security**: Requires `DOCKER_HUB_USER` and `DOCKER_HUB_TOKEN` secrets

## Development Workflows

### Local Development Commands
```bash
# Build latest version locally
docker build -t codex-sandbox:latest .

# Build specific version
docker build --build-arg CODEX_VERSION=0.38.0 -t codex-sandbox:0.38.0 .

# Smoke test the image
docker run --rm codex-sandbox:latest codex --version

# Check if remote version exists
DOCKER_CLI_EXPERIMENTAL=enabled docker manifest inspect benyamin/codex-sandbox:0.38.0
```

### Publishing Process
- Use `./update_docker.sh` script (requires Docker Hub login + buildx setup)
- Script handles version detection, multi-platform builds, and tagging automatically
- Always pushes both versioned tag and `:latest`

## Critical Configuration Details

### Container Environment
- Sets `CODEX_UNSAFE_ALLOW_NO_SANDBOX=1` for container compatibility
- Configures npm global directory at `/usr/local/share/npm-global`
- No default entrypoint - designed as base image or interactive use

### File Structure Conventions
- Root-level scripts use lowercase-hyphen naming (`update_docker.sh`)
- Dockerfile follows ordered layering: system packages → Node.js → npm packages
- Keep comments actionable, not descriptive

### Security Considerations
- Never commit API keys - document in README production checklist
- Image runs as root by default - users should add `--user` flags
- Production deployments need additional sandboxing beyond container isolation

## Common Pitfalls
- Don't add language runtimes - this is minimal image focused on Codex CLI only
- Always test multi-arch builds before pushing (arm64 compatibility)
- Update VERSION.md manually if bypassing automated workflow
- Use conventional commit format for version bumps: `chore: bump Codex to vX.Y.Z`