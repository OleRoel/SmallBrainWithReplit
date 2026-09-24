---
name: LabsLand remote inputs
description: Context behind the DE1-SoC input-debugging reports and the boundary between virtual ports and physical pin assignments.
---

The user's DE1-SoC hardware tests use LabsLand remote web controls, not direct
operation of the physical board switches/buttons.

**Why:** A diagnostic heartbeat worked while physical switch inputs stayed low
and KEY0 stayed released despite web control changes. The user then confirmed
LabsLand access and supplied its generic LL_STD_1 interface diagram and adaptation
guide. The subsequently supplied lab QSF confirmed that virtual controls use
GPIO-connected pins rather than physical switch/button pins. Treat the observed
input failure as a mapping issue, not evidence that the trained network is wrong.
On 2026-09-24, the user confirmed that the corrected LabsLand SOF works on the
remote board with the trained network unchanged. This is user-reported hardware
confirmation, not just a successful local compile; preserve the distinction.

**How to apply:** Distinguish a source upload compiled by LabsLand's fixed
constraints from a locally compiled physical-board SOF. The generic diagram
provides logical port names, not package-pin numbers, and is not proof that
every selectable LabsLand lab uses the same interface. The selected lab's
constraints are now available in the project; use them for remote-lab SOFs
rather than requesting the same diagram again. Do not claim
remote hardware success based on local elaboration or timing checks alone.