# Switch/clock/reset diagnostic image

Use **de1_soc_diagnostic.sof**, not the original de1_soc.sof.
This is a separate diagnostic for the Terasic **DE1-SoC, 5CSEMA5F31C6**.
It does not apply to the original DE1.

Load the file onto the Cyclone V FPGA with Quartus Programmer over USB-Blaster.
Confirm Program/Configure reaches 100% successfully. Keep the board powered;
this volatile configuration is lost at power-off.

## What to observe

| LED | Meaning |
| --- | --- |
| LEDR9 | Permanently on: this image is configured and the LED pin works. No clock or reset required. |
| LEDR8 | Toggles every half-second: the 50 MHz clock is running. KEY0 cannot stop it. |
| LEDR0–3 | Direct copies of SW0–3 after two synchronization clocks. No network or debounce. KEY0 cannot clear them. |
| LEDR4 | KEY0 input is high (normally on when the button is released). |
| LEDR5 | The network's synchronized reset is active (normally off). |
| LEDR6 | Original network output 0: SW0 OR SW2, after debounce. |
| LEDR7 | Original network output 1: SW1 OR SW3, after debounce. |

Use the printed switch/LED labels. SW4–9 and KEY1–3 are unused.

1. Release all buttons. LEDR9 should be on; LEDR8 should blink.
2. Move SW0–3 individually. Each matching LEDR0–3 should follow immediately.
3. Normally LEDR4 is on and LEDR5 is off. Pressing KEY0 should reverse those,
   extinguish LEDR6–7, but leave the heartbeat and switch mirrors working.
4. Release KEY0. LEDR6–7 should resume their network predictions after about 10 ms.

## Interpreting failures

- **LEDR9 off:** check power, the exact board model, programming success, the
  JTAG target, and that this diagnostic file was loaded. Do not blame the network.
- **LEDR9 on but LEDR8 not blinking:** investigate CLOCK_50 and board clock/pin
  compatibility. The switch mirrors also need the clock.
- **Clock blinks but switch mirrors do not follow:** investigate physical switch
  labels, board revision, input pins, or electrical faults.
- **LEDR5 remains on with KEY0 released:** the network is held in reset. Check
  whether LEDR4 is off, the button/pin state, and board compatibility.
- **Switch mirrors and reset are correct but LEDR6–7 stay off:** the fault is
  further along the debounce/network path.

These observations isolate the problem; successful simulation and timing checks
alone do not establish physical board operation.

## Build verification

Built with Quartus Lite 25.1std.0 build 1129 on September 24, 2026:

- All 47 simulation checks passed, including switch mirroring with KEY0 held.
- All analyzed 50 MHz timing corners pass: worst setup slack +1.498 ns,
  worst hold slack +0.176 ns; setup and hold are fully constrained.
- No timing-analysis warnings. Remaining compilation warnings concern the
  deliberately constant LEDR9, subscription-only LogicLock, and default LED
  drive/slew assignments.
- The original network `.sof` remains unchanged.

The cause of the reported all-off LEDs is not yet established. This image is
for collecting physical-board observations, not a claim that the fault is fixed.

## Rebuild in this workspace

From the repository root:

```sh
cabal test switch-led-tests --test-show-details=direct
cabal exec -- sh -c './bin/clash --vhdl DE1SoCDiagnostic.hs -i.local/tool-sources/clash-lib-1.10.2/prims/common -i.local/tool-sources/clash-lib-1.10.2/prims/vhdl -fclash-hdldir vhdl-de1-soc-diagnostic'
./quartus/quartus/bin/quartus_sh -t boards/de1-soc/create_diagnostic.tcl
cd boards/de1-soc
../../quartus/quartus/bin/quartus_sh --flow compile de1_soc_diagnostic
```

See README.md if the compiler's matching primitive sources need restoring.
Inspect `output_files/de1_soc_diagnostic.sta.summary` for negative slack; a
successful Quartus exit status alone does not guarantee timing closure.
The result is `output_files/de1_soc_diagnostic.sof`. The normal project's
configuration and programming file are not overwritten.