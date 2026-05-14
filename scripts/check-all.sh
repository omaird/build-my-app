#!/usr/bin/env bash
# check-all.sh — Aggregate verification suite for the RIZQ App.
#
# Runs all the verification steps that prove a commit/branch is shippable:
#   1. tsc --noEmit            (web type-check)
#   2. eslint .                (web lint)
#   3. npm run build           (web production build)
#   4. npm run test:rules      (Firestore rules unit tests; needs emulator)
#   5. npx playwright test     (web e2e; needs emulator + dev server)
#   6. iOS xcodebuild build    (iOS compile)
#
# Default behavior: fast-fail on first failure.
# Flags:
#   --all          Run every check, accumulate failures, exit non-zero at end if any failed.
#   --skip-ios     Skip the iOS build step.
#   --skip-e2e     Skip Playwright e2e (which requires an emulator + dev server up).
#   --skip-rules   Skip Firestore rules tests (which require the firestore emulator).
#   --web-only     Equivalent to --skip-ios.
#   --ios-only     Run only the iOS xcodebuild step.
#   -v, --verbose  Show full command output (default: suppress on success).
#
# Exit codes:
#   0    all checks passed (or all non-skipped checks passed)
#   1    at least one check failed
#   2    bad invocation / missing dependency

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# ─── colors ─────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  C_RED=$'\033[0;31m'
  C_GREEN=$'\033[0;32m'
  C_YELLOW=$'\033[0;33m'
  C_BLUE=$'\033[0;34m'
  C_BOLD=$'\033[1m'
  C_DIM=$'\033[2m'
  C_RESET=$'\033[0m'
else
  C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_BOLD='' C_DIM='' C_RESET=''
fi

# ─── flags ──────────────────────────────────────────────────────────────────
RUN_ALL=false
SKIP_IOS=false
SKIP_E2E=false
SKIP_RULES=false
IOS_ONLY=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)        RUN_ALL=true ;;
    --skip-ios)   SKIP_IOS=true ;;
    --skip-e2e)   SKIP_E2E=true ;;
    --skip-rules) SKIP_RULES=true ;;
    --web-only)   SKIP_IOS=true ;;
    --ios-only)   IOS_ONLY=true; SKIP_E2E=true; SKIP_RULES=true ;;
    -v|--verbose) VERBOSE=true ;;
    -h|--help)
      sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# //;s/^#//'
      exit 0 ;;
    *)
      echo "${C_RED}unknown flag:${C_RESET} $1" >&2
      echo "use --help to see options" >&2
      exit 2 ;;
  esac
  shift
done

# ─── result tracking ────────────────────────────────────────────────────────
declare -a CHECK_NAMES=()
declare -a CHECK_STATUS=()    # ok | fail | skip
declare -a CHECK_DURATION=()  # in seconds

# Run a single check. Args: <name> <command...>
run_check() {
  local name="$1"; shift
  local start_ts end_ts duration
  start_ts=$(date +%s)

  printf "${C_BLUE}▶${C_RESET} ${C_BOLD}%-22s${C_RESET} " "$name"

  local log_file
  log_file=$(mktemp -t "rizq-check-$$-XXXXXX")
  if "$@" >"$log_file" 2>&1; then
    end_ts=$(date +%s); duration=$((end_ts - start_ts))
    CHECK_NAMES+=("$name"); CHECK_STATUS+=("ok"); CHECK_DURATION+=("$duration")
    printf "${C_GREEN}✓ pass${C_RESET} ${C_DIM}(%ds)${C_RESET}\n" "$duration"
    [[ "$VERBOSE" == "true" ]] && { echo "${C_DIM}--- output ---${C_RESET}"; cat "$log_file"; echo "${C_DIM}---${C_RESET}"; }
    rm -f "$log_file"
    return 0
  else
    end_ts=$(date +%s); duration=$((end_ts - start_ts))
    CHECK_NAMES+=("$name"); CHECK_STATUS+=("fail"); CHECK_DURATION+=("$duration")
    printf "${C_RED}✗ FAIL${C_RESET} ${C_DIM}(%ds)${C_RESET}\n" "$duration"
    echo "${C_DIM}--- last 40 lines of output ---${C_RESET}"
    tail -40 "$log_file"
    echo "${C_DIM}--- full log: $log_file ---${C_RESET}"
    if [[ "$RUN_ALL" == "false" ]]; then
      return 1
    fi
    return 0  # in --all mode, keep going
  fi
}

# Record a skipped check (no command runs)
skip_check() {
  local name="$1" reason="$2"
  CHECK_NAMES+=("$name"); CHECK_STATUS+=("skip"); CHECK_DURATION+=("0")
  printf "${C_BLUE}▶${C_RESET} ${C_BOLD}%-22s${C_RESET} ${C_YELLOW}- skip${C_RESET} ${C_DIM}(%s)${C_RESET}\n" "$name" "$reason"
}

# ─── checks ─────────────────────────────────────────────────────────────────
echo "${C_BOLD}check-all.sh${C_RESET} ${C_DIM}— repo: $REPO_ROOT${C_RESET}"
echo

if [[ "$IOS_ONLY" == "false" ]]; then
  run_check "tsc --noEmit"   npx tsc --noEmit                            || exit 1
  run_check "eslint"         npx eslint .                                 || exit 1
  run_check "vite build"     npm run --silent build                       || exit 1

  if [[ "$SKIP_RULES" == "true" ]]; then
    skip_check "rules tests"     "--skip-rules flag set"
  else
    run_check  "rules tests"     npm run --silent test:rules              || exit 1
  fi

  if [[ "$SKIP_E2E" == "true" ]]; then
    skip_check "playwright e2e"  "--skip-e2e flag set"
  else
    run_check  "playwright e2e"  npx playwright test                      || exit 1
  fi
fi

if [[ "$SKIP_IOS" == "true" ]]; then
  skip_check "ios xcodebuild"   "--skip-ios flag set"
else
  if ! command -v xcodebuild >/dev/null 2>&1; then
    skip_check "ios xcodebuild" "xcodebuild not found"
  elif [[ ! -d "$REPO_ROOT/RIZQ-iOS" ]]; then
    skip_check "ios xcodebuild" "RIZQ-iOS/ not present"
  else
    run_check  "ios xcodebuild" bash -c "cd '$REPO_ROOT/RIZQ-iOS' && xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' build" || exit 1
  fi
fi

# ─── summary ────────────────────────────────────────────────────────────────
echo
echo "${C_BOLD}summary${C_RESET}"
echo "${C_DIM}─────────────────────────────────${C_RESET}"
fail_count=0
total_duration=0
for i in "${!CHECK_NAMES[@]}"; do
  name="${CHECK_NAMES[$i]}"
  status="${CHECK_STATUS[$i]}"
  duration="${CHECK_DURATION[$i]}"
  total_duration=$((total_duration + duration))
  case "$status" in
    ok)   printf "  ${C_GREEN}✓${C_RESET} %-22s ${C_DIM}%ds${C_RESET}\n"  "$name" "$duration" ;;
    fail) printf "  ${C_RED}✗${C_RESET} %-22s ${C_DIM}%ds${C_RESET}\n"    "$name" "$duration"; fail_count=$((fail_count + 1)) ;;
    skip) printf "  ${C_YELLOW}-${C_RESET} %-22s ${C_DIM}skipped${C_RESET}\n" "$name" ;;
  esac
done
echo "${C_DIM}─────────────────────────────────${C_RESET}"
printf "  ${C_DIM}total: %ds${C_RESET}\n" "$total_duration"

if [[ "$fail_count" -gt 0 ]]; then
  printf "${C_RED}%d check(s) failed${C_RESET}\n" "$fail_count"
  exit 1
fi

echo "${C_GREEN}all good${C_RESET}"
exit 0
