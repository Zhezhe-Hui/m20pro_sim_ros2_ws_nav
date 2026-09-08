# M20Pro Sim Scripts

These scripts are local simulation helpers. They do not SSH to 104, install systemd units, record real bags, or control the robot.

```bash
./scripts/start_sim.sh true
./scripts/status_sim.sh
./scripts/stop_sim.sh
```

Use `false` as the first argument to start without RViz:

```bash
./scripts/start_sim.sh false
```

`stop_sim.sh` covers the Python sim nodes plus the Nav2 C++ servers,
`robot_state_publisher`, the static TF publisher, and RViz. It skips its own
process group so it never kills the shell that invoked it, and it force-kills any
survivor that ignores SIGTERM. Always run it before `start_sim.sh`: a second
overlapping instance publishes duplicate TF/pose and makes the robot model jump
around.
