# Terasic DE25-Nano switch-to-LED network

This target is for the **DE25-Nano Agilex 5 SoC**, part
**A5EB013BB23BE4SCS**. It is **not** interchangeable with DE1-SoC or
DE10-Nano images. It uses only FPGA pins; the HPS, LPDDR, HDMI, and GPIO
expansion headers are untouched.

The original trained 4 → 3 → 2 fixed-point network is reused unchanged:

- SW0 or SW2 lights LEDR0; SW1 or SW3 lights LEDR1.
- LEDR2–LEDR7 remain off.
- Press KEY0 (active low) to reset. KEY1 is unused.
- The four mechanical switches synchronize and debounce for 10 ms.

The pin and voltage assignments come from [Terasic's DE25-Nano manual,
rev B](https://www.terasic.com.tw/cgi-bin/page/archive_download.pl?FID=a731718a66ba56b5ba74483b9a0d4a94&Language=English&No=1384),
tables 3-6 and 3-8 through 3-10. CLOCK1_50 is a 3.3 V 50 MHz clock;
the slide switches and eight LEDs use 1.1 V pins. The buttons use 3.3 V.
Confirm the part and board revision against your delivered board before
programming; inspect the Quartus fitted-pin and voltage reports as well.

## Build preparation

From the repository root:

```sh
cabal test switch-led-tests --test-show-details=direct
cabal exec -- sh -c './bin/clash --vhdl DE25Nano.hs -i.local/tool-sources/clash-lib-1.10.2/prims/common -i.local/tool-sources/clash-lib-1.10.2/prims/vhdl -fclash-hdldir vhdl-de25-nano'
cabal exec -- sh -c './bin/clash --vhdl DE25NanoDiagnostic.hs -i.local/tool-sources/clash-lib-1.10.2/prims/common -i.local/tool-sources/clash-lib-1.10.2/prims/vhdl -fclash-hdldir vhdl-de25-nano-diagnostic'
```

**Quartus Prime Pro with Agilex 5 device support** is required to compile
the FPGA image. The Quartus Lite installation in this workspace only includes
Cyclone V support; it cannot produce a trustworthy DE25-Nano `.sof`.
With Pro's `quartus_sh` on PATH:

```sh
quartus_sh -t boards/de25-nano/create_project.tcl
cd boards/de25-nano
quartus_sh --flow compile de25_nano_diagnostic
quartus_sh --flow compile de25_nano
```

Check both `output_files/*.sta.summary` files for **nonnegative setup and
hold slack at every corner** and the timing report for unconstrained paths.
Also inspect all fitted pins, I/O voltage assignments, and any fitter warnings
before loading the resulting `.sof`; a successful exit is not sufficient.
The actual board has not been tested.

## First power-on diagnostic (separate image)

Load **de25_nano_diagnostic.sof** first, after the Pro build above. This
does not depend on the network. Observe:

| LED | Meaning |
| --- | --- |
| LEDR7 | Always on: configuration/pin check |
| LEDR6 | Blinks every half-second: 50 MHz clock |
| LEDR0–3 | Direct synchronized copies of SW0–3 |
| LEDR4 | KEY0 released (normally on) |
| LEDR5 | Synchronized reset active (normally off) |

LEDR0–3 remain responsive while KEY0 is pressed. If those work, load
**de25_nano.sof** and check the trained predictions after approximately
10 ms of steady switch input. A `.sof` programs the FPGA temporarily;
persistent configuration is a separate process.