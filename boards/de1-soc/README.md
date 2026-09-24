# DE1-SoC switch-to-LED network

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

## 2. Create the Quartus project locally

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

**Quartus compilation, timing closure, and physical board operation have not
been verified in this workspace.** The provided Tcl/SDC files are a starting
project configuration to validate locally, not a prebuilt programming image.