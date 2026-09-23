---
name: Clash weight generation
description: Constraints for generating trained fixed-point constants that Clash can synthesize.
---

Generated `SFixed` weights should use Clash's compile-time `fLit` splice rather than
`Data.Ratio` expressions such as `fromRational (n % 256)`. Rational expressions can
leave integer GCD operations in the synthesized hardware graph.

**Why:** Clash synthesis rejected rational weight literals with a missing
`integerGcd` blackbox, while `fLit` compiled the same quantized values directly
into fixed-point constants.

**How to apply:** Quantize training values before rendering, emit `$$(fLit (...))`,
and invoke the installed Clash compiler through Cabal's package environment, for
example `cabal exec -- sh -c './bin/clash --vhdl BrainClash.hs'`.

Install local Clash executables with `--install-method=copy` rather than
relying on Cabal-store symlinks.

**Why:** A later workspace session retained `bin/clash` but not its target
outside the workspace. Earlier successful synthesis did not mean the compiler
was still available; invoking the broken link reported "not found".

**How to apply:** Check that the local compiler actually runs before promising
HDL verification. A source build and Clash simulation alone do not verify HDL
generation.