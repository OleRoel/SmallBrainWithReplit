"""Extract only our top-level ports from the user-supplied LabsLand QSF."""
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ports = (["G_CLOCK_50"] + [f"V_SW[{n}]" for n in range(10)]
         + [f"V_BT[{n}]" for n in range(4)]
         + [f"G_LEDR[{n}]" for n in range(10)])
text = Path(sys.argv[1]).read_text()
locations = {}
standards = {}
for line in text.splitlines():
    match = re.fullmatch(
        r'\s*set_location_assignment\s+(PIN_\w+)\s+-to\s+(\S+)\s*(?:#.*)?', line
    )
    if match and match[2] in ports:
        if match[2] in locations and locations[match[2]] != match[1]:
            raise ValueError(f"Conflicting location for {match[2]}")
        locations[match[2]] = match[1]
    match = re.fullmatch(
        r'\s*set_instance_assignment\s+-name\s+IO_STANDARD\s+"([^"]+)"\s+-to\s+(\S+)\s*(?:#.*)?',
        line,
    )
    if match and match[2] in ports:
        if match[2] in standards and standards[match[2]] != match[1]:
            raise ValueError(f"Conflicting I/O standard for {match[2]}")
        standards[match[2]] = match[1]
assert set(locations) == set(ports), "Missing location assignments"
assert set(standards) == set(ports), "Missing I/O standards"
assert len(set(locations.values())) == len(ports), "Pin collision"
assert set(standards.values()) == {"3.3-V LVTTL"}, "Unexpected I/O standard"
lines = ["# Generated from the supplied LabsLand DE1-SoC QSF; do not edit."]
for port in ports:
    lines.append(f"set_location_assignment {locations[port]} -to {{{port}}}")
    lines.append(
        f'set_instance_assignment -name IO_STANDARD "{standards[port]}" -to {{{port}}}'
    )
(HERE / "pins.tcl").write_text("\n".join(lines) + "\n")
print(f"Imported {len(ports)} unique pins and I/O standards.")