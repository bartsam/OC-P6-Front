#!/usr/bin/env bash

# Strict mode: exit on error (-e), on unset variable (-u) and fail the pipeline if any command in a pipe fails.
set -euo pipefail

# Resolve the script's own directory so it works regardless of the caller's cwd.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$ROOT_DIR/test-results"

# Check whether a directory contains at least one JUnit XML report.
has_junit_reports() {
  compgen -G "$1/*.xml" >/dev/null
}

# Clean up artifacts from a previous run before generating new ones.
rm -rf "$RESULTS_DIR"
mkdir -p "$RESULTS_DIR"

# --- NPM / Angular branch ---
if [[ -f "$ROOT_DIR/package.json" ]]; then
  printf '%s\n' 'npm project detected'

  # Dependency check: npm must be available on the machine running this script.
  if ! command -v npm >/dev/null 2>&1; then
    printf 'ERROR: %s\n' 'npm was not found.' >&2
    exit 1
  fi

  # Install dependencies only if node_modules is missing (first run / fresh checkout).
  if [[ ! -d "$ROOT_DIR/node_modules" ]]; then
    printf '%s\n' 'npm dependencies are missing; running npm ci...'
    npm ci --prefer-offline
  fi

  # Remove any leftover report directory from a previous test run.
  rm -rf "$ROOT_DIR/reports"

  # Run the tests and ...
  TEST_STATUS=0
  if ! npm test; then
    TEST_STATUS=1
  fi

  # Copy the JUnit XML report to the results directory, or fail if missing.
  if has_junit_reports "$ROOT_DIR/reports"; then
    cp "$ROOT_DIR/reports"/*.xml "$RESULTS_DIR/"
  else
    printf 'ERROR: %s\n' 'no Angular JUnit report was generated.' >&2
    TEST_STATUS=1
  fi

  # Exit with the test outcome, whether tests passed or not.
  exit "$TEST_STATUS"
fi

# --- Gradle / Java branch ---
if [[ -f "$ROOT_DIR/build.gradle" ]]; then
  printf '%s\n' 'Gradle project detected'

  # Dependency check: the Gradle wrapper must exist and be executable.
  if [[ ! -x "$ROOT_DIR/gradlew" ]]; then
    printf 'ERROR: %s\n' 'Gradle Wrapper is missing or not executable.' >&2
    exit 1
  fi

  # Dependency check: a JDK must be available on the machine running this script.
  if ! command -v java >/dev/null 2>&1; then
    printf 'ERROR: %s\n' 'Java was not found.' >&2
    exit 1
  fi

  # Remove Gradle report directory from a previous test run.
  GRADLE_REPORTS="$ROOT_DIR/build/test-results/test"
  rm -rf "$GRADLE_REPORTS"

  # Run the tests and preserve their exit status so JUnit reports can still be collected.
  TEST_STATUS=0
  if ! ./gradlew clean test; then
    TEST_STATUS=1
  fi

  # Copy the JUnit XML report to the results directory, or fail if missing.
  if has_junit_reports "$GRADLE_REPORTS"; then
    cp "$GRADLE_REPORTS"/*.xml "$RESULTS_DIR/"
  else
    printf 'ERROR: %s\n' 'no Java JUnit report was generated.' >&2
    TEST_STATUS=1
  fi

  # Exit with the test outcome, whether tests passed or not.
  exit "$TEST_STATUS"
fi

# --- Unsupported project ---
printf 'ERROR: %s\n' 'unsupported project: neither package.json nor build.gradle was found.' >&2
exit 1