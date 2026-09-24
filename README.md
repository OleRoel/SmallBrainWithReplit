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

## DE1-SoC switch-to-LED demo

The **4 → 3 → 2** network now has a dedicated training mode for all 16 switch
combinations:

- **SW0 or SW2 → LED0**
- **SW1 or SW3 → LED1**
- Other LEDs remain off.

```bash
cabal run train -- --switch-leds
cabal test switch-led-tests --test-show-details=direct
cabal exec -- sh -c './bin/clash --vhdl DE1SoC.hs -fclash-hdldir vhdl-de1-soc'
```

`SwitchBrain.hs` holds this demo's generated weights; `SwitchLED.hs` handles
input synchronization, 10 ms debouncing, inference, and LED thresholding.
See [the switch/LED guide](docs/switch-led-demo.md) for the full truth table
and [DE1-SoC Quartus setup](boards/de1-soc/README.md). `DE1SoC.hs` adds KEY0
reset handling and the ten-LED board interface. Servo work remains on the
`servo` branch.

## Train and generate Clash

Run a training pass and inject its quantized weights into `BrainClash.hs`:

```bash
cabal run train
```

The command reads [`BrainClash.template.hs`](./BrainClash.template.hs), replaces
the generated-weight block, and writes [`BrainClash.hs`](./BrainClash.hs).
Treat `BrainClash.hs` as generated output; edit the template instead.

The default architecture is `4 → 3 → 2`. Pass another architecture as
positive layer sizes to the training executable:

```bash
cabal run train -- 4 5 3 2
```

This generates a `4 → 5 → 3 → 2` Clash network.

Compile the Clash library and synthesize VHDL with:

```bash
cabal build brain-clash
cabal exec -- sh -c './bin/clash --vhdl BrainClash.hs'
```

## Docker (outside Replit)

Build the image on a machine with Docker installed:

```bash
docker build -t haskell-brain .
```

The first build compiles Clash 1.10.2 and its dependencies, so it can take
considerable time and disk space. Later builds reuse Docker's cached layers.
The image includes GHC 9.10.3, Cabal, the trainer, and Clash; it intentionally
keeps the compiler toolchain so new architectures can be synthesized at runtime.
The image build also checks that the bundled network synthesizes successfully.

Run the default training demo (prints results, then exits):

```bash
docker run --rm haskell-brain
```

Train the default network and save its generated Haskell and VHDL to a local
`output` directory (commands below use a POSIX shell):

```bash
mkdir -p output
docker run --rm -v "$(pwd)/output:/output" haskell-brain sh -c \
  'cabal run train &&
   cabal exec -- clash --vhdl BrainClash.hs -fclash-hdldir /output/vhdl &&
   cp BrainClash.hs /output/BrainClash.hs'
```

For another architecture, replace `cabal run train` in that command with
`cabal run train -- 4 5 3 2`. For Verilog, replace `--vhdl` with `--verilog`
and use `/output/verilog` for the HDL directory.

Only the mounted output directory persists after `--rm`; without a mount,
generated files are lost when the container is removed. On Linux, files in
the output directory may be owned by root.

This is a command-line batch workload, not a web server: no port mapping is
needed. Run it as a container job on other hosting platforms, not as an HTTP
service. Docker containers are intended to be built and run outside this
Replit workspace.

## Local Clash installation

Clash 1.10.2 is installed in `bin/`.

```bash
./bin/clash --version
./bin/clashi --version
```

[`BrainTrain.hs`](./BrainTrain.hs) contains the reusable training and
serialization logic. [`brain.hs`](./brain.hs) runs the demo without generating
hardware, while [`Train.hs`](./Train.hs) trains and generates the Clash file.