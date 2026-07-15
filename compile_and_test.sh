#!/usr/bin/env bash
# MoonGoons Take Back Godot verification pipeline.

set -Eeuo pipefail

LOG_DIR="logs"
IMPORT_LOG="${LOG_DIR}/godot_import.log"
TEST_LOG="${LOG_DIR}/latest_simulation_run.log"
GODOT_BIN="${GODOT_BIN:-godot}"
FAILURES=0

mkdir -p "${LOG_DIR}"
: > "${IMPORT_LOG}"
: > "${TEST_LOG}"

if ! command -v "${GODOT_BIN}" >/dev/null 2>&1 && [[ ! -x "${GODOT_BIN}" ]]; then
  echo "Godot executable not found. Set GODOT_BIN to a Godot 4.3+ binary path." | tee "${TEST_LOG}"
  exit 1
fi

run_check() {
  local step_label="$1"
  shift
  echo "${step_label}" | tee -a "${TEST_LOG}"
  set +e
  "$@" 2>&1 | tee -a "${TEST_LOG}"
  local exit_code=${PIPESTATUS[0]}
  set -e
  if [[ ${exit_code} -ne 0 ]]; then
    echo "CHECK FAILED: ${step_label} (exit ${exit_code})" | tee -a "${TEST_LOG}"
    FAILURES=1
  fi
}

echo "==========================================================" | tee "${TEST_LOG}"
echo "MOONGOONS TAKE BACK - GODOT VERIFICATION PIPELINE" | tee -a "${TEST_LOG}"
echo "==========================================================" | tee -a "${TEST_LOG}"

echo "[1/19] Importing and parsing project scripts..." | tee "${IMPORT_LOG}" | tee -a "${TEST_LOG}"
set +e
"${GODOT_BIN}" --headless --path . --editor --quit 2>&1 | tee -a "${IMPORT_LOG}" | tee -a "${TEST_LOG}"
IMPORT_EXIT=${PIPESTATUS[0]}
set -e
if [[ ${IMPORT_EXIT} -ne 0 ]]; then
  echo "CHECK FAILED: [1/19] Importing and parsing project scripts... (exit ${IMPORT_EXIT})" | tee -a "${TEST_LOG}"
  FAILURES=1
fi

run_check "[2/19] Running core data and deterministic simulation smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/data_and_simulation_smoke_test.gd
run_check "[3/19] Running complete campaign catalog smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/campaign_catalog_smoke_test.gd
run_check "[4/19] Running Phase Two RTS command and production smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/rts_phase_two_smoke_test.gd
run_check "[5/19] Running Phase Three territory and forward-operations smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/rts_phase_three_smoke_test.gd
run_check "[6/19] Running Phase Four recon, fog, and Tactical Scan smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/rts_phase_four_smoke_test.gd
run_check "[7/19] Running Phase Five Syndicate Siphon Raid smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/rts_phase_five_smoke_test.gd
run_check "[8/19] Running Phase Six developer console smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/rts_phase_six_smoke_test.gd
run_check "[9/19] Running Phase Seven terrain and tactical-map smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/rts_phase_seven_smoke_test.gd
run_check "[10/19] Running Phase Seven queued-route smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/rts_phase_seven_routes_smoke_test.gd
run_check "[11/19] Running Phase Eight Syndicate economy smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/rts_phase_eight_smoke_test.gd
run_check "[12/19] Running Phase Nine fixed-story campaign and difficulty smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/rts_phase_nine_campaign_smoke_test.gd
run_check "[13/19] Running Android touch testbed and export-preset smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/rts_android_testbed_smoke_test.gd
run_check "[14/19] Running web playable export smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/rts_web_playable_smoke_test.gd
run_check "[15/19] Running precinct management and patrol battle smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/precinct_vertical_slice_smoke_test.gd
run_check "[16/19] Running MoonGoons imported-skin overlay smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/moongoons_skin_overlay_smoke_test.gd
run_check "[17/19] Running separate Syndicate reference-content smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/syndicate_campaign_smoke_test.gd
run_check "[18/19] Running living 3D Peacekeeper precinct integration smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/living_precinct_smoke_test.gd
run_check "[19/19] Running cops-side counter-Syndicate campaign smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/counter_syndicate_campaign_smoke_test.gd

echo "==========================================================" | tee -a "${TEST_LOG}"
if [[ ${FAILURES} -eq 0 ]]; then
  echo "SUCCESS: MoonGoons Take Back smoke tests passed." | tee -a "${TEST_LOG}"
else
  echo "FAILED: One or more Godot checks failed. Review the labeled output above." | tee -a "${TEST_LOG}"
fi
echo "Logs: ${IMPORT_LOG} and ${TEST_LOG}" | tee -a "${TEST_LOG}"
echo "==========================================================" | tee -a "${TEST_LOG}"

exit ${FAILURES}
