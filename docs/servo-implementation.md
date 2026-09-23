# Servo PWM implementation

This is code and simulation work only. The timings below are a provisional
hobby-servo interface, **not verified limits for a Diamond D47**. No Quartus
pin assignments, programming file, electrical checks, or board timing results
are supplied. Keep the servo disconnected/unpowered during software work.

## Signal flow

```text
Inputs synchronous to the 50 MHz clock
    -> BrainClash.topEntity: combinational neural-network inference
    -> first output: SFixed 8 8
    -> clamp to [0, 1]
    -> map to pulse width [50,000, 100,000] clock cycles
    -> latch command at a 20 ms frame boundary
    -> compare frame counter against latched pulse width
    -> output register
    -> servo_pwm_out
```

`ServoPWM.hs` implements PWM independently of training. Its standalone
`topEntity` accepts a fixed-point command, so it can be tested without the
network. `BrainServo.hs` connects the first network output to that same PWM
module. The generated `BrainInput` alias lets the wrapper follow changes to
the network input width without editing the wrapper.

Retraining changes `BrainClash.hs`, not the PWM logic. The current network is
still a single-sample training demo, **not a learned motion controller**.
Its first output is usually near 1 and may consequently command near the
upper pulse limit. Selecting output zero is an example mapping, not a claim
that this is an appropriate control policy.

## Timing

| Quantity | Value at 50 MHz |
|---|---|
| Clock period | 20 ns |
| Frame length | 1,000,000 clocks = 20 ms = 50 Hz |
| Command 0 | 50,000 clocks = 1 ms pulse |
| Command 0.5 | 75,000 clocks = 1.5 ms pulse |
| Command 1 | 100,000 clocks = 2 ms pulse |

Commands outside [0, 1] are clamped. `SFixed 8 8` gives 257 command values
within this interval, so this mapping's resolution is about 3.9 microseconds,
not one clock tick. Mapping uses widened integer multiplication and a right
shift, rounding down to a clock count; it does not synthesize a divider.

The `Servo50` domain specifies a 20,000 ps period. This tells Clash the
intended domain; it does **not** create a physical clock or replace a Quartus
50 MHz timing constraint. A different clock requires changing both the domain
and the frame/pulse cycle counts.

## State, enable, and reset

The state contains a frame counter, a latched pulse width, and an active flag.

* Width changes are accepted only when the frame counter is zero. Normal
  command changes cannot lengthen or shorten a pulse already underway.
* Deasserting `servo_enable` stops the pulse at the next clock. This deliberate
  override may truncate a pulse; it does not complete a movement or guarantee
  that a servo releases its holding torque.
* Reasserting enable waits until the next frame boundary (up to 20 ms) before
  starting a new pulse.
* Reset is active-high and synchronous. Assert it across a rising clock edge
  to reset the state and force the output register low.
* After reset release, an enabled controller starts a new frame using the
  current command. The registered output adds one clock of latency without
  changing pulse duration or spacing.

All inputs, including enable and reset, must meet the clock's setup/hold
requirements. Board switches, pushbuttons, and external data sources need
appropriate synchronization. In particular, multibit network inputs need a
coherent transfer protocol if they come from another clock domain. This
wrapper does not implement that interface.

## Build and simulate

From the project root:

```bash
cabal build brain-clash
cabal test servo-tests --test-show-details=direct
```

The tests cover command clamping, complete frame pulse counts, command latching,
enable/disable, pulse termination, and clocked reset/release.

With the local Clash compiler installed, generate standalone PWM or integrated
network/PWM VHDL:

```bash
cabal exec -- sh -c './bin/clash --vhdl ServoPWM.hs'
cabal exec -- sh -c './bin/clash --vhdl BrainServo.hs'
```

If `bin/clash` is missing or is a broken link to an old Cabal store:

```bash
cabal install clash-ghc-1.10.2 --installdir=bin \
  --install-method=copy --overwrite-policy=always -j2
```

This can be a substantial first build. Inside the Docker image, use `clash`
instead of `./bin/clash`; it is installed on PATH. For example:

```bash
docker run --rm haskell-brain cabal test servo-tests
```

## Later hardware integration

The intended signal is `GPIO_0[13]` on JP1, **not physical header pin 13**.
Before creating a programming file:

1. Verify the D47's supply voltage, peak current, logic threshold, and allowed
   pulse widths against its documentation.
2. Verify the board revision, exact FPGA package-pin mapping, and header wiring.
3. Add Quartus clock, reset, I/O-standard, and pin assignments.
4. Decide how network inputs and enable reach the FPGA synchronously.
5. Run Quartus compilation/timing analysis, then measure the unloaded PWM pin
   with a scope or logic analyzer before attaching the servo.

A GPIO output is never a servo ground or power supply. Power and common-ground
wiring remain a separate, deferred hardware check.