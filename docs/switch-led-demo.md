# Four switches → trained network → two LEDs

This demo lives on `main`. The earlier servo work is preserved on the `servo`
branch; it is not used by this design.

The current physical target is **DE1-SoC**. The board-specific wrapper and
Quartus project generator are described in
[boards/de1-soc/README.md](../boards/de1-soc/README.md). The generic
`SwitchLED` core below retains its four-switch/eight-LED interface; `DE1SoC`
adapts it to ten red LEDs and the active-low KEY0 button.

## Behaviour

The 4 → 3 → 2 ReLU network learns:

- LED0 = SW0 OR SW2
- LED1 = SW1 OR SW3
- LED2…LED7 = off

Input vector order is **SW0, SW1, SW2, SW3**. When written as a binary number,
the switch bus is **SW3 SW2 SW1 SW0** (SW0 is bit zero).

| SW3…SW0 | LED1 LED0 |
|---|---|
| 0000 | 00 |
| 0001 | 01 |
| 0010 | 10 |
| 0011 | 11 |
| 0100 | 01 |
| 0101 | 01 |
| 0110 | 11 |
| 0111 | 11 |
| 1000 | 10 |
| 1001 | 11 |
| 1010 | 10 |
| 1011 | 11 |
| 1100 | 11 |
| 1101 | 11 |
| 1110 | 11 |
| 1111 | 11 |

The OR rule generates training labels and test expectations only. The hardware
actually evaluates the trained network and thresholds its two outputs at 0.5.
This is a teaching example; implementing this Boolean rule directly would use
far less FPGA logic than a network.

## Training and verification

```bash
cabal run train -- --switch-leds
cabal test switch-led-tests --test-show-details=direct
```

Training uses all 16 input patterns for 20,000 epochs with a fixed random seed
(42), making the weights repeatable. It rejects incorrect floating-point
classifications before exporting. The subsequent tests separately run **the
generated `SFixed 8 8` model** for all 16 patterns. Always run those tests after
retraining: passing the floating-point check alone is not sufficient.

The weights are written to `SwitchBrain.hs`, using `BrainClash.template.hs`.
They are deliberately separate from `BrainClash.hs`: the existing
`cabal run train -- 4 5 3 2` experiments must not change the board demo's
four-input/two-output interface.

## Hardware structure

```text
SW[3:0]
  -> two input register stages, clocked at 50 MHz
  -> whole-vector debounce: require 10 ms of stable switches
  -> switch bits converted to fixed-point 0 or 1
  -> trained first layer -> hidden-activation register -> trained second layer
  -> each output >= 0.5
  -> registered LED[7:0], with bits 7…2 zero
```

There is no apply button. Moving switches updates the LEDs automatically after
the input has settled for about 10 ms. The two input register stages provide
the intended synchronizer structure; hardware metastability/timing analysis
was recognized in Quartus (five two-stage chains including reset). Debouncing suppresses normal mechanical bounce
but cannot guarantee an atomic update when a person moves multiple switches
far apart in time.

Top-level ports in `SwitchLED.hs`:

- `CLOCK_50`: 50 MHz clock.
- `RESET`: active-high, synchronous reset; hold high over a rising clock edge.
- `SW`: four switch bits.
- `LED`: eight output bits, logical high means on.

Reset clears the pipeline and LED output. The physical DE10-Nano pushbutton
polarity/interface must be adapted if a button is used for reset; do not wire
an asynchronous button directly to this synchronous reset assumption.

## Generate VHDL

```bash
cabal build brain-clash
cabal exec -- sh -c './bin/clash --vhdl SwitchLED.hs -fclash-hdldir vhdl-switch-led'
```

Select **switch_led** as the Quartus top-level entity and include the generated
dependencies, not just the top-level VHDL file. The generated HDL directory
contains the manifest and subordinate network modules.

If the local Clash executable is missing/broken, restore it first:

```bash
cabal install clash-ghc-1.10.2 --installdir=bin \
  --install-method=copy --overwrite-policy=always -j2
```

This may take several minutes on a fresh workspace.

For the Docker image, use `clash` from PATH rather than `./bin/clash`:

```bash
docker run --rm haskell-brain cabal test switch-led-tests
```

## What is not yet board-verified

The DE1-SoC design has been compiled with Quartus Lite 25.1 and meets the 20 ns
clock constraint in all analyzed timing corners. The network has a register
between its two layers; fixed-point calculations and weights are unchanged.
See the board README for the programming image and timing results.
Confirm the board revision before programming. Physical-board operation has
not been tested. The servo wiring is irrelevant; leave it disconnected.