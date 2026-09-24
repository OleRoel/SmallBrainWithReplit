# LabsLand DE1-SoC programming images and sources

## Direct .sof upload (recommended)

Upload **labsland_switch_led.sof** to the LabsLand DE1-SoC bitstream uploader.
No source compilation in the web editor is required.

- Virtual switch **9 OFF**: run. **9 ON**: reset.
- Virtual switches 0 OR 2 drive LED0 through the trained network.
- Virtual switches 1 OR 3 drive LED1 through the trained network.
- LED2–9 stay off; allow approximately 10 ms for stable switch changes.

The separate **labsland_diagnostic.sof** uses the indicator table below.
Both images target Cyclone V **5CSEMA5F31C6** and use the virtual-input pins
from the supplied LabsLand DE1-SoC QSF, not the physical switch pins.

### Build verification

Built with Quartus Lite 25.1std.0 build 1129 on 2026-09-24.
All analyzed 50 MHz timing corners pass:

| Image | Worst setup slack | Worst hold slack |
| --- | --- | --- |
| Normal network | +1.938 ns | +0.264 ns |
| Diagnostic | +1.608 ns | +0.176 ns |

Both timing reports show zero unconstrained input/output ports or paths and
zero unconstrained clocks. All 25 fitted port locations, directions and
I/O standards were checked against the uploaded QSF. Compilation warnings
include deliberately constant LEDs, unused controls, default I/O settings,
and subscription-only LogicLock. These are not hardware-test results.

## Optional source upload

These files adapt the existing trained, pipelined Clash network to the
**LL_STD_1 interface in the supplied LabsLand diagram**:
`G_CLOCK_50`, `V_SW[9:0]`, `V_BT[3:0]`, `G_LEDR[9:0]`.
The arithmetic and trained weights are unchanged.

## Use

1. Open the LabsLand VHDL editor. Check that its documentation lists the
   names above. The supplied diagram is generic; if your selected DE1-SoC
   lab lists different names, obtain its interface/constraints before use.
2. Upload or paste **one complete VHDL file**, not both. Each file contains
   all dependencies and has top-level entity **main**.
3. Have LabsLand compile the source and program the board. Do **not** upload
   the previous physical-board `.sof` as a replacement for this step.
4. Set virtual switch **9 OFF** to run the network. Switch 9 ON resets it.
   This deliberately avoids depending on undocumented virtual-button polarity.

### Start with `labsland_diagnostic.vhdl`

| LED | Meaning |
| --- | --- |
| 9 | Always on |
| 8 | Toggles every half-second |
| 0–3 | Synchronized virtual switches 0–3; independent of reset |
| 4 | Raw synchronized virtual button 0 level; polarity is not assumed |
| 5 | Synchronized virtual switch 9 (reset request, not the internal reset signal) |
| 6 | Trained network output 0: switch 0 OR switch 2 |
| 7 | Trained network output 1: switch 1 OR switch 3 |

With switch 9 OFF, each virtual switch 0–3 should change its matching LED.
Network outputs follow after approximately 10 ms of stable input.
Switch 9 ON clears the network outputs but not the input mirrors/heartbeat.
Press and release virtual button 0 to check LED4; it does not reset the network.

### Then use `labsland_switch_led.vhdl`

LED0 is the trained prediction for switch 0 OR switch 2.
LED1 is the trained prediction for switch 1 OR switch 3.
LED2–9 are off. Switch 9 remains the active-high reset.

## Why a source upload is needed

LabsLand applies a fixed constraints file to its named virtual interface.
The old `.sof` was compiled for physical switches and KEY0, not this interface.
Renaming ports does not change an already compiled `.sof`.

The supplied diagram and guide specify logical ports, **not FPGA package
pin numbers**. The user subsequently supplied the actual LabsLand DE1-SoC
QSF. Its selected port assignments are preserved in `boards/labsland/pins.tcl`.
Do not substitute standard physical-board pin assignments.

Source: https://labsland.com/blog/en/2020/03/12/how-to-adapt-external-vhdl-or-verilog-codes-or-external-practices-to-the-labsland-fpga-laboratory/

## Rebuild and check

From the repository root, after generating the normal DE1-SoC Clash HDL:

```sh
python boards/labsland/package_sources.py
./quartus/quartus/bin/quartus_sh -t boards/labsland/check_sources.tcl
tar -cJf deliverables/labsland-switch-led.tar.xz -C deliverables labsland
```

The check performs Quartus VHDL analysis and elaboration for both files.
It does not perform placement/routing, establish timing closure, or verify
LabsLand hardware operation. LabsLand's own compilation and hardware run
are needed for the source-upload route.

To reproduce the local programming-image builds after generating the source
bundles, run:

```sh
# Optional re-import if the lab supplies updated constraints:
# python boards/labsland/import_pins.py /path/to/LabsLand-DE1-SoC.qsf
./quartus/quartus/bin/quartus_sh -t boards/labsland/create_projects.tcl
cd boards/labsland
../../quartus/quartus/bin/quartus_sh --flow compile labsland_switch_led
../../quartus/quartus/bin/quartus_sh --flow compile labsland_diagnostic
```

Inspect both `output_files/*.sta.summary` files for negative slack before
distributing the corresponding `.sof` files. A successful command exit alone
does not establish timing closure.