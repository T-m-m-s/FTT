import subprocess

svg = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <rect width="512" height="512" rx="116" fill="#0B0E14" />
  
  <g transform="translate(256, 256)">
    <!-- Triangolo Superiore (Punta in basso: il tempo che scorre) Viola #6C5CE7 -->
    <path d="M -110 -115
             C -120 -115, -125 -105, -119 -95
             L -10 -12
             C -5 -4, 5 -4, 10 -12
             L 119 -95
             C 125 -105, 120 -115, 110 -115
             Z"
          fill="#6C5CE7" />

    <!-- Triangolo Inferiore (Punta in alto: il tempo accumulato/tracciato) Ciano #38BDF8 -->
    <path d="M -110 115
             C -120 115, -125 105, -119 95
             L -10 12
             C -5 4, 5 4, 10 12
             L 119 95
             C 125 105, 120 115, 110 115
             Z"
          fill="#38BDF8" />
          
    <!-- Piccolo granello/punto focale al centro -->
    <circle cx="0" cy="0" r="10" fill="#FFFFFF" />
  </g>
</svg>"""

with open("docs/icons/svg/test_hourglass_clean.svg", "w") as f:
    f.write(svg)

subprocess.run(["resvg", "-w", "1024", "-h", "1024", "docs/icons/svg/test_hourglass_clean.svg", "docs/icons/test_hourglass_clean.png"], check=True)
