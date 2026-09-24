# Haskell Brain

A small feed-forward neural network in Haskell using ReLU activations and
stochastic gradient descent.

## Run

```bash
cabal run brain
```

## Build

```bash
cabal build
```

## Train and synthesize

Generate a new `BrainClash.hs` from a training run:

```bash
cabal run train
```

Then compile and synthesize it:

```bash
cabal build brain-clash
cabal exec -- sh -c './bin/clash --vhdl BrainClash.hs'
```

`BrainClash.template.hs` is the hand-written source. `BrainClash.hs` is
generated output and should not be edited manually. Pass layer sizes after
`--` to generate another architecture, for example:

```bash
cabal run train -- 4 5 3 2
```

## Clash HDL

The Clash compiler and interactive shell are installed in `bin/`:

```bash
./bin/clash --version
./bin/clashi --version
```

## Project files

The current `main` branch focuses on four switches and two LED outputs:
SW0/SW2 → LED0, SW1/SW3 → LED1. Train via `cabal run train -- --switch-leds`
and validate via `cabal test switch-led-tests`.
Keep generated `SwitchBrain.hs` separate from generic `BrainClash.hs`
architecture experiments so they cannot break the fixed board interface.
The board target is DE1-SoC (not the original DE1). `DE1SoC.hs` adapts reset
and LED width; `boards/de1-soc` contains manual-verified pins and a Quartus
project generator. Quartus Lite 25.1 is installed under `quartus/` (ignored).
The layer-pipelined design passes 50 MHz timing; physical board operation is
not yet verified. See `docs/switch-led-demo.md` and `boards/de1-soc/README.md`.
Servo experiments remain preserved on the `servo` branch.

- `BrainTrain.hs` — reusable training and Clash-source generation logic
- `brain.hs` — training demo
- `Train.hs` — trains and generates `BrainClash.hs`
- `BrainClash.template.hs` — hand-written Clash template
- `BrainClash.hs` — generated Clash inference source
- `brain.cabal` — Cabal executable and Clash library definitions
- `cabal.project` — Cabal project configuration
- `README.md` — user-facing project instructions