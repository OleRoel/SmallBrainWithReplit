# LabsLand source upload

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
pin numbers**. A corrected local `.sof` requires the actual constraints file
for this lab. Do not guess GPIO pin assignments or reuse physical switch pins.

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
remain necessary.