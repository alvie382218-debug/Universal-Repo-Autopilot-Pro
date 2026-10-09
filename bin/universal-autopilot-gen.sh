#!/usr/bin/env bash
set -Eeuo pipefail

export LC_ALL=C.UTF-8
export LANG=C.UTF-8

REPO_URL="${1:-}"
TMP_BASE="${TMPDIR:-/tmp}"
WORKDIR="${TMP_BASE}/repo-autopilot-$$"
OUTDIR="${HOME}/.repo-autopilots"
mkdir -p "${OUTDIR}" "${WORKDIR}"

print_banner() {
  echo
  echo "╔══════════════════════════════════════════════════════════════════════╗"
  echo "║ Universal Repository Autopilot Pro                                 ║"
  echo "║ Autonomous Repo Analysis + Setup + Security Reporting              ║"
  echo "╚══════════════════════════════════════════════════════════════════════╝"
  echo
}

fail() {
  echo "ERROR: $*" >&2
  rm -rf "${WORKDIR}"
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

validate_url() {
  [[ -n "${REPO_URL}" ]] || fail "Usage: $0 https://github.com/owner/repo"
  if [[ "${REPO_URL}" =~ github\.com/([^/]+)/([^/]+)(\.git)?/?$ ]]; then
    REPO_OWNER="${BASH_REMATCH[1]}"
    REPO_NAME="${BASH_REMATCH[2]}"
  else
    fail "Invalid GitHub URL. Use: https://github.com/owner/repo"
  fi
}

clone_repo() {
  echo "[1/5] Cloning repository..."
  git clone --depth=1 "https://github.com/${REPO_OWNER}/${REPO_NAME}.git" "${WORKDIR}/repo" >/dev/null 2>&1 || fail "Could not clone repository"
}

infer_language() {
  local repo_path="${WORKDIR}/repo"
  local lang="unknown"

  [[ -f "${repo_path}/package.json" ]] && lang="javascript"
  [[ -f "${repo_path}/pyproject.toml" || -f "${repo_path}/requirements.txt" || -f "${repo_path}/setup.py" ]] && lang="python"
  [[ -f "${repo_path}/go.mod" ]] && lang="golang"
  [[ -f "${repo_path}/Cargo.toml" ]] && lang="rust"
  [[ -f "${repo_path}/pom.xml" || -f "${repo_path}/build.gradle" ]] && lang="java"
  [[ -f "${repo_path}/Dockerfile" || -f "${repo_path}/docker-compose.yml" ]] && lang="docker"

  echo "${lang}"
}

infer_framework() {
  local repo_path="${WORKDIR}/repo"
  if grep -Eq "django|flask|fastapi" "${repo_path}/requirements.txt" "${repo_path}/pyproject.toml" 2>/dev/null; then
    echo "python-web"
  elif grep -Eq "react|next|vue" "${repo_path}/package.json" 2>/dev/null; then
    echo "frontend"
  elif grep -Eq "express|fastify|nest" "${repo_path}/package.json" 2>/dev/null; then
    echo "node-backend"
  elif grep -Eq "spring|quarkus" "${repo_path}/pom.xml" "${repo_path}/build.gradle" 2>/dev/null; then
    echo "java-backend"
  else
    echo "generic"
  fi
}

scan_basic_security() {
  local repo_path="${WORKDIR}/repo"
  local findings=()

  if grep -R -nE 'API_KEY|SECRET_KEY|PRIVATE_KEY|BEGIN PRIVATE KEY|ghp_|AKIA|aws_access_key_id|password\s*[:=]|token\s*[:=]' "${repo_path}" 2>/dev/null | head -n 20; then
    findings+=("Potential hardcoded secret or credential found")
  fi

  if grep -R -nE 'DEBUG\s*=\s*True|CORS_ORIGIN\s*=\s*\*|ALLOW_ALL_ORIGINS|SECRET_KEY\s*=\s*""' "${repo_path}" 2>/dev/null | head -n 20; then
    findings+=("Potential insecure configuration found")
  fi

  if [[ ${#findings[@]} -eq 0 ]]; then
    echo "No obvious issues detected in quick scan"
  else
    printf '%s\n' "${findings[@]}"
  fi
}

create_autopilot_script() {
  local target_file="${OUTDIR}/${REPO_OWNER}-${REPO_NAME}-autopilot.sh"
  cat > "${target_file}" <<AUTOPILOT
#!/usr/bin/env bash
set -Eeuo pipefail

export LC_ALL=C.UTF-8
export LANG=C.UTF-8

REPO_URL="${REPO_URL}"
TARGET_DIR="\${HOME}/\${REPO_NAME:-${REPO_NAME}}"
LOGDIR="\${HOME}/.${REPO_NAME}-autopilot"
mkdir -p "\${LOGDIR}"

echo "Starting autopilot for ${REPO_OWNER}/${REPO_NAME}"
if ! command -v git >/dev/null 2>&1; then
  echo "Installing git..."
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -qq && sudo apt-get install -y git
  elif command -v brew >/dev/null 2>&1; then
    brew install git
  elif command -v apk >/dev/null 2>&1; then
    apk add --no-cache git
  else
    echo "Git install not supported automatically on this OS"
  fi
fi

git clone --depth=1 "\${REPO_URL}" "\${TARGET_DIR}" || true

echo "Repository cloned to \${TARGET_DIR}"
echo "Ready for manual verification and additional security testing"
AUTOPILOT

  chmod +x "${target_file}"
  echo "Autopilot script created: ${target_file}"
}

print_summary() {
  local lang="$(infer_language)"
  local framework="$(infer_framework)"
  echo
  echo "Project Analysis:"
  echo "  Owner: ${REPO_OWNER}"
  echo "  Repo: ${REPO_NAME}"
  echo "  Language: ${lang}"
  echo "  Framework: ${framework}"
  echo "  Scan result:"
  scan_basic_security || true
  echo
}

main() {
  print_banner
  require_cmd git
  validate_url
  clone_repo
  print_summary
  create_autopilot_script
  echo
  echo "✅ Analysis complete."
  echo "→ To run the generated setup/security helper:"
  echo "   ${OUTDIR}/${REPO_OWNER}-${REPO_NAME}-autopilot.sh"
  echo
  rm -rf "${WORKDIR}"
}

main "$@"
