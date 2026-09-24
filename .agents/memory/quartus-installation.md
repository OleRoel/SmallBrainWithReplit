---
name: Quartus installation on NixOS
description: Use Altera's online installer rather than obsolete direct-download URLs; command-line operation works with glib.
---

Altera's `qinst-lite-linux` upload is an online bootstrapper, not the full
Quartus package. Its CLI can download Quartus and Cyclone V support without
an interactive browser login.

**Why:** The old direct Intel installer URLs in the Nix package redirected
instead of returning software. The user-provided Altera bootstrapper's own
connection test and installation succeeded. Assuming the browser login
also blocks the bootstrapper would incorrectly stop installation.

**How to apply:** Inspect the uploaded installer's `--help`. Use its documented
CLI and select only the required components. On this NixOS environment it
needed the `glib` system dependency; its shell launcher sets up the bundled
libraries, so direct `ldd` output on the internal executable can misleadingly
report libraries missing. Test the shell launcher before adding dependencies.
Do not assume an installer upload includes device support or that installation
success establishes FPGA compilation or timing closure.