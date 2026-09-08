import subprocess
from pathlib import Path

out_dir = Path("docs/icons")
svg_dir = out_dir / "svg"
svg_dir.mkdir(parents=True, exist_ok=True)

# Palette
DARK_BG = "#0B0E14"
PURPLE = "#6C5CE7"
CYAN = "#38BDF8"

# -------------------------------------------------------------
# 1. OPZIONE 1: LA CLESSIDRA / PLAY (The Hourglass-Play Synthesis)
# Un'icona geometrica perfetta:
# Una clessidra orizzontale / doppio triangolo contrapposto che forma
# al tempo stesso la clessidra (tempo) e la freccia Play (svago).
# Costruita con due triangoli morbidi arrotondati (rx=24) che si sfiorano al centro con un gap di 18px.
# -------------------------------------------------------------
svg1 = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <rect width="512" height="512" rx="116" fill="{DARK_BG}" />
  
  <g transform="translate(256, 256)">
    <!-- Triangolo Sinistro: cuspide a destra verso il centro -->
    <path d="M -130 -110
             C -130 -125, -112 -135, -98 -126
             L 0 -50
             C 12 -42, 12 -24, 0 -16
             L -98 60
             C -112 69, -130 59, -130 44
             Z"
          fill="{PURPLE}"
          transform="translate(-16, 0)" />

    <!-- Triangolo Destro: play puro slanciato in avanti -->
    <path d="M 0 -85
             C 0 -100, 18 -109, 31 -101
             L 135 -38
             C 148 -30, 148 -10, 135 -2
             L 31 61
             C 18 69, 0 60, 0 45
             Z"
          fill="{CYAN}"
          transform="translate(16, 0)" />
  </g>
</svg>"""

# -------------------------------------------------------------
# 2. OPZIONE 2: IL MONOGRAMMA F CINETICO (The Kinetic 'F')
# Una "F" solida, architettonica e futuristica stile Linear / Formula 1.
# La spina dorsale a sinistra, e due ali orizzontali tagliate a 45° che sfrecciano a destra.
# -------------------------------------------------------------
svg2 = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <rect width="512" height="512" rx="116" fill="{DARK_BG}" />

  <g transform="translate(256, 256)">
    <!-- Pilastro Verticale di Sinistra (Spina dorsale dell'F) -->
    <rect x="-115" y="-120" width="52" height="240" rx="26" fill="{PURPLE}" />

    <!-- Braccio Superiore (Lungo, slanciato a 45°) -->
    <path d="M -45 -120
             L 95 -120
             C 112 -120, 124 -105, 117 -89
             L 95 -68
             C 90 -61, 82 -56, 73 -56
             L -45 -56
             C -55 -56, -63 -64, -63 -74
             L -63 -102
             C -63 -112, -55 -120, -45 -120 Z"
          fill="{PURPLE}" />

    <!-- Braccio Centrale (Intermedio, slanciato a 45°) -->
    <path d="M -45 -18
             L 45 -18
             C 62 -18, 74 -3, 67 13
             L 45 34
             C 40 41, 32 46, 23 46
             L -45 46
             C -55 46, -63 38, -63 28
             L -63 0
             C -63 -10, -55 -18, -45 -18 Z"
          fill="{PURPLE}" />

    <!-- Accento geometrico solido: puntatore Play in ciano -->
    <circle cx="85" cy="100" r="16" fill="{CYAN}" />
  </g>
</svg>"""

# -------------------------------------------------------------
# 3. OPZIONE 3: IL CONTROLLER ARROTONDATO (Stile Discord / Clyde)
# Una silhouette a controller con proporzioni impeccabili:
# Rettangolo orizzontale 300x190 con rx=60, arco inferiore morbido R=100
# e intaglio Play centrale equilatero netto.
# -------------------------------------------------------------
svg3 = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <rect width="512" height="512" rx="116" fill="{DARK_BG}" />

  <g transform="translate(256, 256)">
    <!-- Sagoma Solida del Controller (Viola #6C5CE7) -->
    <!-- Curve continue pulite, niente bozze asimmetriche -->
    <path d="M -150 -90
             C -80 -105, 80 -105, 150 -90
             C 175 -85, 190 -65, 185 -40
             L 170 40
             C 165 70, 140 95, 110 95
             C 90 95, 70 80, 55 65
             C 35 45, -35 45, -55 65
             C -70 80, -90 95, -110 95
             C -140 95, -165 70, -170 40
             L -185 -40
             C -190 -65, -175 -85, -150 -90 Z"
          fill="{PURPLE}" />

    <!-- Intaglio Negativo Centrale (Play Triangle perfetto nello stesso colore dello sfondo) -->
    <path d="M -22 -44
             C -22 -52, -13 -57, -6 -53
             L 42 -22
             C 49 -18, 49 -8, 42 -4
             L -6 27
             C -13 31, -22 26, -22 18
             Z"
          fill="{DARK_BG}" />
  </g>
</svg>"""

# -------------------------------------------------------------
# 4. OPZIONE 4: IL QUADRANTE MECCANICO (Stile Steam Linkage)
# Un disco perfetto R=100 e un disco piccolo R=42 uniti da rette tangenti pulite a 25 gradi.
# Con due fori concentrici netti.
# -------------------------------------------------------------
svg4 = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <rect width="512" height="512" rx="116" fill="{DARK_BG}" />

  <g transform="translate(256, 256)">
    <!-- Corpo Meccanico Unico (Viola #6C5CE7) -->
    <!-- Centro grande a (-45, 0), Centro piccolo a (105, 0) -->
    <path d="M -45 -105
             A 105 105 0 0 0 -45 105
             L 105 52
             A 52 52 0 0 0 105 -52
             L -45 -105 Z"
          fill="{PURPLE}" />

    <!-- Foro Principale Negativo (Il Quadrante/Tempo) -->
    <circle cx="-45" cy="0" r="54" fill="{DARK_BG}" />

    <!-- Foro Secondario Negativo (Il Perno) -->
    <circle cx="105" cy="0" r="24" fill="{DARK_BG}" />

    <!-- Accento Ciano nel foro secondario: come un indicatore o gemma -->
    <circle cx="105" cy="0" r="12" fill="{CYAN}" />
  </g>
</svg>"""

pro_icons = [
    ("pro_opt1_hourglass_play.svg", svg1),
    ("pro_opt2_kinetic_f.svg", svg2),
    ("pro_opt3_discord_controller.svg", svg3),
    ("pro_opt4_steam_linkage.svg", svg4),
]

for filename, content in pro_icons:
    filepath = svg_dir / filename
    filepath.write_text(content)
    png_path = out_dir / filename.replace(".svg", ".png")
    subprocess.run(["resvg", "-w", "1024", "-h", "1024", str(filepath), str(png_path)], check=True)
    print(f"Rendered {png_path}")

