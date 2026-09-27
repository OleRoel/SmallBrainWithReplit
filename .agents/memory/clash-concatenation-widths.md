---
name: Clash concatenation widths
description: Why one-bit boolean conversions in chained BitVector concatenation need explicit widths.
---

When concatenating several boolean-derived `BitVector`s with `++#`, annotate
each `boolToBV` result as `BitVector 1`.

**Why:** GHC cannot always infer the widths of intermediate nested
concatenations from the final vector size. The type error presents several
ambiguous type-level naturals even though the desired sum seems obvious.

**How to apply:** In new board diagnostics or similar HDL, specify widths at
the conversions before concatenating. Prefer the compiler's type error over
changing the intended LED layout to make inference work.