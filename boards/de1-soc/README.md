# DE1-SoC switch-to-LED network

If switches appear unresponsive, use the separate
[diagnostic image and LED guide](DIAGNOSTIC.md) to distinguish configuration,
clock, input wiring, and reset problems.

Target: Terasic **DE1-SoC**, Cyclone V **5CSEMA5F31C6** (device marking may
include an `N` suffix). This is not the original DE1 or the DE10-Nano.

The existing 4 → 3 → 2 trained network is unchanged:

- SW0 or SW2 lights LEDR0.
- SW1 or SW3 lights LEDR1.
- LEDR2–LEDR9 stay off.
- KEY0 resets the design (pressed = low).
- SW4–SW9 and KEY1–KEY3 are unused.

Switches pass through synchronization and 10 ms debouncing. KEY0 passes through
two clocked reset synchronizer stages; reset assertion and release are delayed
by clock cycles. The stages power up asserted so the circuit starts in reset.

## Verified reference, not a claim of board testing

Pin assignments and polarity were checked against Terasic's
[DE1-SoC User Manual v1.2.2, rev E, April 2 2015](https://people.ece.cornell.edu/land/courses/ece5760/DE1_SOC/DE1-SoC_User_manualv.1.2.2_revE.pdf),
tables 3-5, 3-6, 3-7, and 3-8 (pages 22–26). This is a university-hosted copy
of the manufacturer manual; other revisions are available from
[Terasic's resources page](https://www.terasic.com.tw/cgi-bin/page/archive.pl?CategoryNo=165&Language=English&No=836&PartNo=4).
Confirm your board/device matches before programming.

## 1. Generate and test on the development machine

From the repository root:

```sh
cabal test switch-led-tests --test-show-details=direct
cabal exec -- sh -c './bin/clash --vhdl DE1SoC.hs -fclash-hdldir vhdl-de1-soc'
```

The checked-in `SwitchBrain.hs` already contains trained weights. Retraining is
optional: `cabal run train -- --switch-leds`, followed by the tests above.
In the Docker image use `clash` from PATH instead of `./bin/clash`.

If a restored workspace retains the Clash executable but loses its Cabal
data files, HDL generation can fail with missing BlackBox definitions.
Restore the matching primitive definitions without rebuilding the compiler:

```sh
cabal get clash-lib-1.10.2 --destdir=.local/tool-sources
cabal exec -- sh -c './bin/clash --vhdl DE1SoC.hs -i.local/tool-sources/clash-lib-1.10.2/prims/common -i.local/tool-sources/clash-lib-1.10.2/prims/vhdl -fclash-hdldir vhdl-de1-soc'
```

Skip `cabal get` if that source directory already exists.

## 2. Create the Quartus project locally

Quartus Lite 25.1 with Cyclone V support is also installed in this workspace
under `quartus/`. Its command-line entry point, from the repository root, is
`./quartus/quartus/bin/quartus_sh`. The installation is excluded from Git.

Install a Quartus edition/version that supports Cyclone V, including its device
support package. Copy the project **including `vhdl-de1-soc`** to that machine.
From the repository root:

```sh
quartus_sh -t boards/de1-soc/create_project.tcl
cd boards/de1-soc
quartus_sh --flow compile de1_soc
```

Alternatively, open the generated `boards/de1-soc/de1_soc.qpf` in Quartus and
start compilation. Rerun `create_project.tcl` after regenerating HDL or moving
the checkout: it refreshes the generated file list, including all dependencies.
It reapplies the supplied device, pins, and timing file while retaining other
local assignments.

`timing.sdc` constrains the 50 MHz clock to 20 ns, excludes asynchronous
input-port paths and untimed LED output paths, and leaves the internal
register-to-register paths timed. Review Timing Analyzer setup/hold reports,
unconstrained paths, and synchronizer/metastability reports before programming.
Do not ignore warnings about missing pins, unmatched constraints, or timing
failures. In particular, confirm the two-stage synchronizers remain intact.

## 3. Program and observe

Connect the board's FPGA USB-Blaster programming interface, select it in
Quartus Programmer, auto-detect the chain, and assign
`output_files/de1_soc.sof` to the Cyclone V FPGA device. Enable Program/Configure.
Use volatile `.sof` programming first; no flash programming is required.
No HPS Linux setup is needed.

After programming, press and release KEY0. Try SW0, SW1, SW2, and SW3
individually and together; LEDR0/1 should follow the mapping after about 10 ms.
Keep any servo/external GPIO wiring disconnected.

## Verified build (September 24, 2026)

Quartus Lite 25.1std.0 build 1129 successfully compiled the design for
5CSEMA5F31C6. `output_files/de1_soc.sof` is the volatile FPGA programming image.
The first unpipelined build failed timing; a hidden-layer register now splits
inference into two clock cycles without changing trained weights or arithmetic.
All 28 simulation checks pass, including streamed comparison of all 16 patterns.

- Worst setup slack: **+1.784 ns** at 50 MHz.
- Worst hold slack: **+0.243 ns**.
- Setup/hold are fully constrained; all reported timing corners pass.
- Resources: 306 ALMs, 85 registers, 18 DSP blocks.
- Five two-stage synchronizers are recognized. Numerical MTBF was not calculated
  because synchronizers were auto-detected rather than explicitly designated.
- Remaining compilation warnings concern deliberately constant LEDR2–9,
  unavailable subscription-only LogicLock, and default LED drive strength/slew.
  No timing-analysis warnings remain.

**Physical board operation has not been verified.** Confirm the device and board
revision, and use volatile `.sof` programming before considering flash storage.
Quartus can report successful compilation even with negative timing slack:
always inspect timing reports after future changes or retraining.