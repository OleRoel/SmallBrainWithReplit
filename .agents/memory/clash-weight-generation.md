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

Check the local compiler executable after changing branches or restoring a
workspace; use Cabal's `--install-method=copy` when restoring it.

**Why:** The repository's compiler link can survive while its external Cabal
store target is missing. Past successful synthesis does not establish that
the compiler is available in the current workspace.

**How to apply:** Verify `bin/clash --version` before an HDL check. Reinstall
when needed, and distinguish passing simulation from successful HDL generation.