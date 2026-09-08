import subprocess
from pathlib import Path

out_dir = Path("docs/icons")
svg_dir = out_dir / "svg"

# 1. Monogram F con punto ciano (F.)
cp1 = "docs/icons/test_unified_f.png"

# 2. Clessidra Pura (Hourglass)
cp2 = "docs/icons/test_hourglass_clean.png"

# 3. Fast-Forward (Due frecce Play calibrate)
cp3 = "docs/icons/pro_opt1_hourglass_play.png"

# 4. Monogram F Assoluto (Solo 2 colori: Viola su Nero Ossidiana, senza punto)
svg_f_pure = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <rect width="512" height="512" rx="116" fill="#0B0E14" />
  
  <g transform="translate(256, 256)">
    <!-- F Monolitica pura al 100% in Viola Reale #6C5CE7 -->
    <path d="M -100 -130
             L 100 -130
             C 115 -130, 125 -118, 120 -105
             L 105 -80
             C 100 -72, 90 -68, 80 -68
             L -35 -68
             L -35 -22
             L 60 -22
             C 75 -22, 85 -10, 80 3
             L 65 28
             C 60 36, 50 40, 40 40
             L -35 40
             L -35 110
             C -35 125, -50 135, -65 130
             C -85 125, -100 105, -100 85
             Z"
          fill="#6C5CE7" />
  </g>
</svg>"""

with open(svg_dir / "final_opt4_f_pure.svg", "w") as f:
    f.write(svg_f_pure)

subprocess.run(["resvg", "-w", "1024", "-h", "1024", str(svg_dir / "final_opt4_f_pure.svg"), str(out_dir / "final_opt4_f_pure.png")], check=True)

# Copy/link the other 3
subprocess.run(["cp", cp1, str(out_dir / "final_opt1_monogram_f_dot.png")], check=True)
subprocess.run(["cp", cp2, str(out_dir / "final_opt2_hourglass.png")], check=True)
subprocess.run(["cp", cp3, str(out_dir / "final_opt3_fast_forward.png")], check=True)

print("All 4 final options organized!")
