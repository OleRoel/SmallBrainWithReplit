# Brain

A small feed-forward neural network in Haskell using ReLU activations and
stochastic gradient descent. The runnable version uses pure Haskell matrix
operations, so it does not need native BLAS/LAPACK libraries.

## Run

From the project root:

```bash
cabal run brain
```

The demo creates a `4 → 3 → 2` network, trains it on one sample for 100
iterations, and prints the output before and after training.

## Build

```bash
cabal build
```

## Train and generate Clash

Run a training pass and inject its quantized weights into `BrainClash.hs`:

```bash
cabal run train
```

The command reads [`BrainClash.template.hs`](./BrainClash.template.hs), replaces
the generated-weight block, and writes [`BrainClash.hs`](./BrainClash.hs).
Treat `BrainClash.hs` as generated output; edit the template instead.

Compile the Clash library and synthesize VHDL with:

```bash
cabal build brain-clash
cabal exec -- sh -c './bin/clash --vhdl BrainClash.hs'
```

## Clash HDL

Clash 1.10.2 is installed in `bin/`.

```bash
./bin/clash --version
./bin/clashi --version
```

[`BrainTrain.hs`](./BrainTrain.hs) contains the reusable training and
serialization logic. [`brain.hs`](./brain.hs) runs the demo without generating
hardware, while [`Train.hs`](./Train.hs) trains and generates the Clash file.