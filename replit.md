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
generated output and should not be edited manually.

## Clash HDL

The Clash compiler and interactive shell are installed in `bin/`:

```bash
./bin/clash --version
./bin/clashi --version
```

## Project files

- `BrainTrain.hs` — reusable training and Clash-source generation logic
- `brain.hs` — training demo
- `Train.hs` — trains and generates `BrainClash.hs`
- `BrainClash.template.hs` — hand-written Clash template
- `BrainClash.hs` — generated Clash inference source
- `brain.cabal` — Cabal executable and Clash library definitions
- `cabal.project` — Cabal project configuration
- `README.md` — user-facing project instructions