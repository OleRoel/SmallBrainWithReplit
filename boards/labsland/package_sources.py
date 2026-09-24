"""Bundle existing Clash HDL with the LabsLand interface; no retraining."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CORE = ROOT / "vhdl-de1-soc" / "DE1SoC.topEntity"
OUT = ROOT / "deliverables" / "labsland"


def main():
    core = "\n\n".join(
        (CORE / filename).read_text()
        for filename in ("de1_soc_types.vhdl", "de1_soc.vhdl")
    )
    template = (Path(__file__).parent / "wrapper.vhdl").read_text()
    OUT.mkdir(parents=True, exist_ok=True)
    for name, diagnostic in (("switch_led", False), ("diagnostic", True)):
        wrapper = template.replace("@DIAGNOSTIC@", str(diagnostic).lower())
        (OUT / f"labsland_{name}.vhdl").write_text(
            "-- Upload this complete file by itself. Top-level entity: main.\n"
            + core + "\n\n" + wrapper
        )
    (OUT / "README.md").write_text(
        (Path(__file__).parent / "README.md").read_text()
    )


if __name__ == "__main__":
    main()