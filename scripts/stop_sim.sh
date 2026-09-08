#!/usr/bin/env bash
set -euo pipefail

patterns=(
  "m20pro_sim.launch.py"
  "m20pro_dual_lidar_simulator"
  "m20pro_dynamic_obstacle_simulator"
  "m20pro_sim_health_monitor"
  "m20pro_pointcloud_fusion"
  "m20pro_web_dashboard"
  "m20pro_navigation/lib"
  "nav2_map_server/map_server"
  "nav2_controller/controller_server"
  "nav2_planner/planner_server"
  "nav2_bt_navigator/bt_navigator"
  "nav2_behaviors/behavior_server"
  "nav2_smoother/smoother_server"
  "nav2_waypoint_follower"
  "nav2_velocity_smoother"
  "nav2_lifecycle_manager/lifecycle_manager"
  "robot_state_publisher/robot_state_publisher"
  "tf2_ros/static_transform_publisher"
  "rviz2"
)

# Fields: pid pgid args. Skip this script, its caller, its process group, and any
# helper command line that merely quotes the patterns above.
self_pid=$$
self_pgid=$(ps -o pgid= -p "$$" | tr -d ' ')
self_ppid=${PPID:-0}

list_pids() {
  local filter="$1"
  ps -eo pid=,pgid=,args= | awk \
    -v filter="${filter}" \
    -v self_pid="${self_pid}" \
    -v self_ppid="${self_ppid}" \
    -v self_pgid="${self_pgid}" \
    '$1 != self_pid && $1 != self_ppid && $2 != self_pgid && $0 !~ /awk/ && $0 !~ /stop_sim\.sh|status_sim\.sh|start_sim\.sh/ && $0 ~ filter {print $1}'
}

survivor_filter='install/m20pro|nav2_|robot_state_publisher|rviz2'

for pattern in "${patterns[@]}"; do
  mapfile -t pids < <(list_pids "${pattern}")
  if [[ "${#pids[@]}" -gt 0 ]]; then
    echo "[stop_sim] stopping ${pattern}: ${pids[*]}"
    kill "${pids[@]}" 2>/dev/null || true
  fi
done

sleep 2

# Nav2 C++ servers occasionally ignore SIGTERM and keep their topics alive.
mapfile -t survivors < <(list_pids "${survivor_filter}")
if [[ "${#survivors[@]}" -gt 0 ]]; then
  echo "[stop_sim] force stopping survivors: ${survivors[*]}"
  kill -9 "${survivors[@]}" 2>/dev/null || true
  sleep 1
fi

mapfile -t remaining < <(list_pids "${survivor_filter}")
if [[ "${#remaining[@]}" -gt 0 ]]; then
  echo "[stop_sim] WARNING still running: ${remaining[*]}"
  ps -o pid=,args= -p "${remaining[@]}" 2>/dev/null || true
else
  echo "[stop_sim] all simulation processes stopped"
fi
