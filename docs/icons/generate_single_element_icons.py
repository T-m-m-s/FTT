import subprocess
from pathlib import Path

out_dir = Path("docs/icons")
svg_dir = out_dir / "svg"
svg_dir.mkdir(parents=True, exist_ok=True)

# -------------------------------------------------------------
# 1. THE STEAM CAM (La Camma Meccanica / Hub & Play)
# Come Steam: un unico pezzo solido con intagli negativi precisi.
# Un cerchio centrale (il tempo) fuso con un cuneo Play a destra, con foro centrale.
# -------------------------------------------------------------
svg1 = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <!-- Sfondo Solido 1: Scuro Grafite -->
  <rect x="16" y="16" width="480" height="480" rx="112" fill="#0C1017" />

  <!-- Elemento Unico Solido: Viola #6C5CE7 -->
  <!-- Un disco (R=120) a coordinate (230, 256) fuso con una punta Play a (370, 256) -->
  <path d="M 230 126
           A 130 130 0 0 0 115 320
           L 115 320
           A 130 130 0 0 0 320 320
           L 385 275
           C 400 265, 400 247, 385 237
           L 320 192
           A 130 130 0 0 0 230 126 Z"
        fill="#6C5CE7" />

  <!-- Intaglio Negativo (Colore Sfondo): Foro centrale come un orologio/disco -->
  <circle cx="230" cy="256" r="56" fill="#0C1017" />
  <!-- Piccolo accento solido al centro: l'asse/perno -->
  <circle cx="230" cy="256" r="22" fill="#38BDF8" />
</svg>
"""

# -------------------------------------------------------------
# 2. THE GEMINI SPARK / PLAY STAR (La Stella a 4 Punte / Play)
# Come Gemini: una forma geometrica a stella con curve concave,
# ma con la punta destra estesa che forma un play in avanti.
# -------------------------------------------------------------
svg2 = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <!-- Sfondo Solido Scuro -->
  <rect x="16" y="16" width="480" height="480" rx="112" fill="#0C1017" />

  <!-- Elemento Unico Solido: Ciano Elettrico #38BDF8 -->
  <!-- Stella a 4 punte concave: Alto (256, 120), Basso (256, 392), Sinistra (150, 256), Destra (390, 256) -->
  <path d="M 240 115
           C 240 190, 195 240, 140 240
           C 195 240, 240 290, 240 397
           C 240 290, 310 240, 400 240
           C 310 240, 240 190, 240 115 Z"
        fill="#38BDF8" />

  <!-- Intaglio centrale negativo: un piccolo rombo/diamante dello stesso colore dello sfondo -->
  <polygon points="255,230 275,240 255,250 235,240" fill="#0C1017" />
</svg>
"""

# -------------------------------------------------------------
# 3. THE DISCORD CLYDE STYLE CONTROLLER (La Sagoma Iconica)
# Un unico blocco iconico arrotondato con intaglio Play negativo
# -------------------------------------------------------------
svg3 = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <!-- Sfondo Solido Scuro -->
  <rect x="16" y="16" width="480" height="480" rx="112" fill="#0C1017" />

  <!-- Elemento Unico: Viola #6C5CE7 -->
  <!-- Silhouette stilizzata: base controller morbida ed essenziale -->
  <path d="M 175 160
           C 215 170, 297 170, 337 160
           C 365 153, 390 175, 385 205
           L 370 295
           C 365 325, 330 340, 305 320
           L 275 295
           C 265 287, 247 287, 237 295
           L 207 320
           C 182 340, 147 325, 142 295
           L 127 205
           C 122 175, 147 153, 175 160 Z"
        fill="#6C5CE7" />

  <!-- Intaglio Negativo Centrale (Play Triangle perfetto nel colore dello sfondo) -->
  <path d="M 235 210
           C 235 203, 243 198, 249 202
           L 295 236
           C 301 240, 301 249, 295 253
           L 249 287
           C 243 291, 235 286, 235 279 Z"
        fill="#0C1017" />
</svg>
"""

# -------------------------------------------------------------
# 4. THE WALLET / SWITCH DUO (Due Blocchi Fissi: Pausa & Play)
# Stile Google Wallet / Nintendo Switch: due forme geometriche piatte
# Colori: Viola Solido + Ciano Solido su fondo scuro
# -------------------------------------------------------------
svg4 = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <!-- Sfondo Solido Scuro -->
  <rect x="16" y="16" width="480" height="480" rx="112" fill="#0C1017" />

  <!-- Blocco 1 (Sinistra): Colonna Barra Arrotondata (Viola #6C5CE7) -->
  <rect x="145" y="156" width="60" height="200" rx="30" fill="#6C5CE7" />

  <!-- Blocco 2 (Destra): Triangolo Play Arrotondato (Ciano #38BDF8) -->
  <path d="M 245 166
           C 245 153, 260 145, 271 152
           L 375 242
           C 385 250, 385 262, 375 270
           L 271 360
           C 260 367, 245 359, 245 346 Z"
        fill="#38BDF8" />
</svg>
"""

single_element_icons = [
    ("concept_se1_steam_cam.svg", svg1),
    ("concept_se2_gemini_spark.svg", svg2),
    ("concept_se3_discord_clyde.svg", svg3),
    ("concept_se4_switch_duo.svg", svg4),
]

for filename, content in single_element_icons:
    filepath = svg_dir / filename
    filepath.write_text(content)
    png_path = out_dir / filename.replace(".svg", ".png")
    subprocess.run(["resvg", "-w", "1024", "-h", "1024", str(filepath), str(png_path)], check=True)
    print(f"Rendered {png_path}")

