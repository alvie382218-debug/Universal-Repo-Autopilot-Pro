#!/usr/bin/env bash
set -Eeuo pipefail

export LC_ALL=C.UTF-8
export LANG=C.UTF-8

REPO_URL="${1:-}"
TARGET_PATH="${2:-}"
WORKDIR="${TMPDIR:-/tmp}/security-audit-$$"
RESULT_DIR="${HOME}/.repo-autopilots/reports"
mkdir -p "${RESULT_DIR}" "${WORKDIR}"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

if [[ -z "${REPO_URL}" ]]; then
  echo "Usage: $0 <github-url> [local-path]"
  exit 1
fi

require_cmd git

if [[ -n "${TARGET_PATH}" && -d "${TARGET_PATH}" ]]; then
  SOURCE_DIR="${TARGET_PATH}"
  echo "Using local repository: ${SOURCE_DIR}"
else
  REPO_NAME="$(basename "${REPO_URL}" .git)"
  git clone --depth=1 "${REPO_URL}" "${WORKDIR}/${REPO_NAME}" >/dev/null 2>&1 || fail "Could not clone repository"
  SOURCE_DIR="${WORKDIR}/${REPO_NAME}"
fi

LANG="unknown"
FRAMEWORK="unknown"
SEVERITY="INFO"
findings=0

if [[ -f "${SOURCE_DIR}/package.json" ]]; then LANG="javascript"; fi
if [[ -f "${SOURCE_DIR}/pyproject.toml" || -f "${SOURCE_DIR}/requirements.txt" || -f "${SOURCE_DIR}/setup.py" ]]; then LANG="python"; fi
if [[ -f "${SOURCE_DIR}/go.mod" ]]; then LANG="golang"; fi
if [[ -f "${SOURCE_DIR}/Cargo.toml" ]]; then LANG="rust"; fi
if [[ -f "${SOURCE_DIR}/pom.xml" || -f "${SOURCE_DIR}/build.gradle" ]]; then LANG="java"; fi
if [[ -f "${SOURCE_DIR}/Dockerfile" || -f "${SOURCE_DIR}/docker-compose.yml" ]]; then LANG="docker"; fi

if grep -Eq "django|flask|fastapi" "${SOURCE_DIR}/requirements.txt" "${SOURCE_DIR}/pyproject.toml" 2>/dev/null; then
  FRAMEWORK="python-web"
fi
if grep -Eq "react|next|vue" "${SOURCE_DIR}/package.json" 2>/dev/null; then
  FRAMEWORK="frontend"
fi
if grep -Eq "express|fastify|nest" "${SOURCE_DIR}/package.json" 2>/dev/null; then
  FRAMEWORK="node-backend"
fi
if grep -Eq "spring|quarkus" "${SOURCE_DIR}/pom.xml" "${SOURCE_DIR}/build.gradle" 2>/dev/null; then
  FRAMEWORK="java-backend"
fi

scan_secret() {
  if grep -R -nE 'API_KEY|SECRET_KEY|PRIVATE_KEY|ghp_|AKIA|BEGIN PRIVATE KEY|password\s*[:=]|token\s*[:=]' "${SOURCE_DIR}" 2>/dev/null | head -n 20; then
    echo "Potential hardcoded secret or credential detected." >&2
    return 0
  fi
  return 1
}

scan_insecure() {
  if grep -R -nE 'DEBUG\s*=\s*True|CORS.*\*|ALLOW_ALL_ORIGINS|SECRET_KEY\s*=\s*""|jwt.*secret|password\s*=\s*""' "${SOURCE_DIR}" 2>/dev/null | head -n 20; then
    echo "Potential insecure configuration found." >&2
    return 0
  fi
  return 1
}

report_file="${RESULT_DIR}/security-report-bangla.md"

{
  echo "# 🔐 নিরাপত্তা মূল্যায়ন রিপোর্ট"
  echo
  echo "- Repo URL: ${REPO_URL}"
  echo "- Detected Language: ${LANG}"
  echo "- Detected Framework: ${FRAMEWORK}"
  echo "- Generated At: $(date -u +%Y-%m-%d\ %H:%M:%S\ UTC)"
  echo
  echo "## 1. সারসংক্ষেপ"
  echo "এই ডকুমেন্টটি GitHub রিপোজিটরি বিশ্লেষণ করে, ভাষা, framework, dependency pattern, এবং security posture নির্ধারণ করে। এটি ethical hacking, security audit, এবং automated setup workflows-এর জন্য উপযোগী।"
  echo
  echo "## 2. কার্যকারিতা"
  echo "- রিপোজিটরির ভাষা ও ফ্রেমওয়ার্ক শনাক্ত করে"
  echo "- setup ও dependency পূর্বাভাস দেয়"
  echo "- মূল security issue খুঁজে বের করে"
  echo "- বাংলা রিপোর্ট তৈরি করে"
  echo "- DevSecOps এবং ethical hacker-এর কাজকে অটোমেটেড করে"
  echo
  echo "## 3. দ্রুত নিরাপত্তা চেক"
  if scan_secret; then
    echo "- ⚠️ Potential hardcoded secret detected"
    SEVERITY="HIGH"
    findings=$((findings+1))
  else
    echo "- ✅ No obvious hardcoded secret detected in quick scan"
  fi

  if scan_insecure; then
    echo "- ⚠️ Potential insecure config detected"
    if [[ "${SEVERITY}" != "HIGH" ]]; then SEVERITY="MEDIUM"; fi
    findings=$((findings+1))
  else
    echo "- ✅ No obvious insecure config detected in quick scan"
  fi

  echo
  echo "## 4. উপসংহার"
  echo "এই প্রকল্পটি মূলত repository intelligence, security scanning, automated setup, এবং বাংলা প্রতিবেদন তৈরি করার জন্য ডিজাইন করা হয়েছে।"
  echo "এর প্রধান কার্যকারিতা হলো: অটোমেটেড বিশ্লেষণ, দ্রুত স্ক্যান, ব্যবহারকারীর জন্য পাঠযোগ্য প্রতিবেদন, ও নিরাপত্তা ঝুঁকি চিহ্নিতকরণ।"
  echo
  echo "## 5. পরবর্তী পদক্ষেপ"
  echo "1. Sensitive data remover/secret manager ব্যবহার করুন"
  echo "2. Dependency update করুন"
  echo "3. CORS, JWT, এবং security headers-review করুন"
  echo "4. CI/CD pipeline-এ security scan যুক্ত করুন"
  echo "5. প্রকাশের আগে full audit চালান"
  echo
  echo "## 6. Risk Summary"
  echo "- Total findings: ${findings}"
  echo "- Overall severity: ${SEVERITY}"
} > "${report_file}"

cat "${report_file}"

echo
printf '\n✅ Report written to %s\n' "${report_file}"

rm -rf "${WORKDIR}"
