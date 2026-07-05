#!/usr/bin/env bash
# MoonGoons Take Back Godot verification pipeline.
# Run locally after installing Godot 4.3+:
#   chmod +x compile_and_test.sh
#   ./compile_and_test.sh

set -Eeuo pipefail

LOG_DIR="logs"
IMPORT_LOG="${LOG_DIR}/godot_import.log"
TEST_LOG="${LOG_DIR}/latest_simulation_run.log"
GODOT_BIN="${GODOT_BIN:-godot}"

mkdir -p "${LOG_DIR}"

if ! command -v "${GODOT_BIN}" >/dev/null 2>&1 && [[ ! -x "${GODOT_BIN}" ]]; then
  echo "Godot executable not found. Set GODOT_BIN to a Godot 4.3+ binary path." | tee "${TEST_LOG}"
  exit 1
fi

echo "==========================================================" | tee "${TEST_LOG}"
echo "MOONGOONS TAKE BACK - GODOT VERIFICATION PIPELINE" | tee -a "${TEST_LOG}"
echo "==========================================================" | tee -a "${TEST_LOG}"

echo "[1/5] Importing and parsing project scripts..." | tee "${IMPORT_LOG}"
"${GODOT_BIN}" --headless --path . --editor --quit 2>&1 | tee -a "${IMPORT_LOG}"

echo "[2/5] Running core data and deterministic simulation smoke tests..." | tee -a "${TEST_LOG}"
"${GODOT_BIN}" --headless --path . --script res://tests/data_and_simulation_smoke_test.gd 2>&1 | tee -a "${TEST_LOG}"

echo "[3/5] Running complete campaign catalog smoke tests..." | tee -a "${TEST_LOG}"
"${GODOT_BIN}" --headless --path . --script res://tests/campaign_catalog_smoke_test.gd 2>&1 | tee -a "${TEST_LOG}"

echo "[4/5] Running Phase Two RTS command and production smoke tests..." | tee -a "${TEST_LOG}"
"${GODOT_BIN}" --headless --path . --script res://tests/rts_phase_two_smoke_test.gd 2>&1 | tee -a "${TEST_LOG}"

echo "[5/5] Running Phase Three territory and forward-operations smoke tests..." | tee -a "${TEST_LOG}"
"${GODOT_BIN}" --headless --path . --script res://tests/rts_phase_three_smoke_test.gd 2>&1 | tee -a "${TEST_LOG}"

echo "==========================================================" | tee -a "${TEST_LOG}"
echo "SUCCESS: MoonGoons Take Back smoke tests passed." | tee -a "${TEST_LOG}"
echo "Logs: ${IMPORT_LOG} and ${TEST_LOG}" | tee -a "${TEST_LOG}"
echo "==========================================================" | tee -a "${TEST_LOG}"
