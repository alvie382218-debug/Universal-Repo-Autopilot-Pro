#!/usr/bin/env bash
set -Eeuo pipefail

LANG="bengali"
SOURCE_DIR="${1:-}"
REPORT_PATH="${2:-${HOME}/.repo-autopilots/reports/usage-report.md}"
mkdir -p "$(dirname "${REPORT_PATH}")"

if [[ -z "${SOURCE_DIR}" ]]; then
  echo "Usage: $0 <repo-path> [report-path]"
  exit 1
fi

if [[ ! -d "${SOURCE_DIR}" ]]; then
  echo "Repository directory not found: ${SOURCE_DIR}"
  exit 1
fi

cat > "${REPORT_PATH}" <<REPORT
# 📘 ব্যবহারকারী রিপোর্ট (বাংলা)

## ১. প্রজেক্টের উদ্দেশ্য

এই প্রজেক্টটি GitHub রিপোজিটরি থেকে তথ্য সংগ্রহ করে, ভাষা ও framework শনাক্ত করে, security risk বিশ্লেষণ করে, এবং ব্যবহারকারীর জন্য একটি সহজ ও কার্যকর সমাধান তৈরি করে।

## ২. কাজের ধরন

- repo diagnosis
- dependency pattern check
- security scanning
- setup assistance
- report generation

## ৩. কার্যকরীতা

এই টুলটি প্রকৃতপক্ষে এমন একজন ব্যবহারকারীর জন্য উপযোগী যিনি দ্রুত বুঝতে চান:

- আমার repository কোন ধরনের app?
- এতে কোন ভাষা ও framework ব্যবহার করা হয়েছে?
- কোন sensitive data exposure আছে কি?
- setup করতে কী কী dependency দরকার?
- নিরাপত্তা ঝুঁকি কোথায়?
- বাংলা রিপোর্টে কীভাবে ফলাফল দেখানো যায়?

## ৪. ব্যবহারকারী রিপোর্ট

প্রকল্পটি একটি "আর্কিটেকচার + অটোমেশন + নিরাপত্তা" সমাধান। এটি ডেভেলপার এবং security analyst-এর জন্য খুব কার্যকর।

### সুবিধা

- দ্রুত repo inspection
- অটোমেটেড reconnaissance
- setup/autopilot generation
- risk detection
- user readable output
- Bengali summary

### চ্যালেঞ্জ

- repo must be valid and authorized
- no destructive actions
- static analysis is limited by context
- external services need network access

## ৫. উপসংহার

এই টুলের মূল গুণ হলো এটি কেবল প্রযুক্তিগত বিশ্লেষণ করে না, বরং ব্যবহারকারীর জন্য ব্যাখ্যা ও প্রতিবেদনও তৈরি করে। এটি ethical hacking, automation, এবং project readiness এর একটি মডেল হিসেবে কাজ করতে পারে।

## ৬. পরবর্তী পদক্ষেপ

1. GitHub repo URL দিন
2. অটোমেটেড scan চালান
3. Findings পড়ুন
4. Security fixের আগে authorized scope নিশ্চিত করুন
5. রিপোর্টটি team/sharing purposeে ব্যবহার করুন

---

প্রতিবেদন তৈরি হয়েছে: $(date -u +%Y-%m-%d\ %H:%M:%S\ UTC)
REPORT

echo "✅ Bengali usage report generated: ${REPORT_PATH}"
