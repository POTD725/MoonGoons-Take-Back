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

echo "[ART] Generating approved station and cinematic artwork..." | tee -a "${TEST_LOG}"
python3 tools/generate_approved_station_art.py 2>&1 | tee -a "${TEST_LOG}"
python3 tools/generate_approved_cinematic_art.py 2>&1 | tee -a "${TEST_LOG}"
test -s assets/generated/approved_station_deck.svg
for frame in crater_market_blackout ghost_key_heist station_reactivation patrol_launch syndicate_assault victory_reclaim; do
  test -s "assets/generated/cinematics/${frame}.svg"
done

echo "[1/29] Importing and parsing project scripts..." | tee "${IMPORT_LOG}" | tee -a "${TEST_LOG}"
set +e
"${GODOT_BIN}" --headless --path . --editor --quit 2>&1 | tee -a "${IMPORT_LOG}" | tee -a "${TEST_LOG}"
IMPORT_EXIT=${PIPESTATUS[0]}
set -e
if [[ ${IMPORT_EXIT} -ne 0 ]]; then
  echo "CHECK FAILED: [1/29] Importing and parsing project scripts... (exit ${IMPORT_EXIT})" | tee -a "${TEST_LOG}"
  FAILURES=1
fi

run_check "[2/29] Running core data and deterministic simulation smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/data_and_simulation_smoke_test.gd
run_check "[3/29] Running complete campaign catalog smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/campaign_catalog_smoke_test.gd
run_check "[4/29] Running Phase Two RTS command and production smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/rts_phase_two_smoke_test.gd
run_check "[5/29] Running Phase Three territory and forward-operations smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/rts_phase_three_smoke_test.gd
run_check "[6/29] Running Phase Four recon, fog, and Tactical Scan smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/rts_phase_four_smoke_test.gd
run_check "[7/29] Running Phase Five Syndicate Siphon Raid smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/rts_phase_five_smoke_test.gd
run_check "[8/29] Running Phase Six developer console smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/rts_phase_six_smoke_test.gd
run_check "[9/29] Running Phase Seven terrain and tactical-map smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/rts_phase_seven_smoke_test.gd
run_check "[10/29] Running Phase Seven queued-route smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/rts_phase_seven_routes_smoke_test.gd
run_check "[11/29] Running Phase Eight Syndicate economy smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/rts_phase_eight_smoke_test.gd
run_check "[12/29] Running Phase Nine fixed-story campaign and difficulty smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/rts_phase_nine_campaign_smoke_test.gd
run_check "[13/29] Running Android touch testbed and export-preset smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/rts_android_testbed_smoke_test.gd
run_check "[14/29] Running web playable export smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/rts_web_playable_smoke_test.gd
run_check "[15/29] Running precinct management and patrol battle smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/precinct_vertical_slice_smoke_test.gd
run_check "[16/29] Running MoonGoons imported-skin overlay smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/moongoons_skin_overlay_smoke_test.gd
run_check "[17/29] Running separate Syndicate reference-content smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/syndicate_campaign_smoke_test.gd
run_check "[18/29] Running living 3D Peacekeeper precinct integration smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/living_precinct_smoke_test.gd
run_check "[19/29] Running cops-side counter-Syndicate campaign smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/counter_syndicate_campaign_smoke_test.gd
run_check "[20/29] Running shared space-station hull and automatic door smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/space_station_hull_smoke_test.gd
run_check "[21/29] Running individual room equipment and mission-board smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/precinct_equipment_and_missions_smoke_test.gd
run_check "[22/29] Running engine, weapons, medical, and interrogation side-operation puzzles..." "${GODOT_BIN}" --headless --path . --script res://tests/side_operations_smoke_test.gd
run_check "[23/29] Running asteroid, moon, wreck harvesting and Syndicate space-combat smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/resource_harvesting_and_space_threats_smoke_test.gd
run_check "[24/29] Running shared Syndicate Rising origin and attack cinematic smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/shared_origin_cinematics_smoke_test.gd
run_check "[25/29] Running Alliance Construction, Technology, and Weapons Level 1-100 smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/alliance_research_tree_smoke_test.gd
run_check "[26/29] Running station-deck picture icon and hover-card smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/station_icon_hover_smoke_test.gd
run_check "[27/29] Running approved station artwork and facility hotspot smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/approved_station_art_smoke_test.gd
run_check "[28/29] Running approved animated cinematic artwork smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/approved_cinematic_art_smoke_test.gd
run_check "[29/29] Running Syndicate Rising portrait layout parity smoke tests..." "${GODOT_BIN}" --headless --path . --script res://tests/syndicate_layout_parity_smoke_test.gd

echo "==========================================================" | tee -a "${TEST_LOG}"
if [[ ${FAILURES} -eq 0 ]]; then
  echo "SUCCESS: MoonGoons Take Back smoke tests passed." | tee -a "${TEST_LOG}"
else
  echo "FAILED: One or more Godot checks failed. Review the labeled output above." | tee -a "${TEST_LOG}"
fi
echo "Logs: ${IMPORT_LOG} and ${TEST_LOG}" | tee -a "${TEST_LOG}"
echo "==========================================================" | tee -a "${TEST_LOG}"

exit ${FAILURES}
