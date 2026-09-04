# Brain

A small feed-forward neural network in Haskell using ReLU activations and
stochastic gradient descent.

## Run

From the project root:

```bash
cabal run
```

The demo creates a `4 → 3 → 2` network, trains it on one sample for 100
iterations, and prints the output before and after training.

## Build

```bash
cabal build
```

The main source is [`brain.hs`](./brain.hs). Its functions can also be reused
from another Haskell module by moving the network definitions into a library
module.