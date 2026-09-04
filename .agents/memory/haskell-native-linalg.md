---
name: Haskell native linear algebra
description: Compatibility guidance for Haskell projects using hmatrix and BLAS/LAPACK in this workspace.
---

Prefer pure-Haskell matrix operations for small Haskell demos in this workspace unless a known-compatible LP64 BLAS/LAPACK toolchain is explicitly configured.

**Why:** The available OpenBLAS package is built with `USE64BITINT`, while hmatrix expects the LP64 BLAS ABI. The program can compile but emits invalid DGEMM parameter errors at runtime.

**How to apply:** If a future project needs hmatrix, verify the BLAS integer ABI before using it. For small examples, avoid the native dependency rather than relying on environment-specific linker paths.