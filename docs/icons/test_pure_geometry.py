import subprocess
from pathlib import Path

out_dir = Path("docs/icons")
svg_dir = out_dir / "svg"

# -------------------------------------------------------------------------
# 1. THE GEMINI-STYLE ASTROID / 4-POINT STAR (Costruzione geometrica perfetta)
# 4 archi di cerchio perfetti di raggio R=200 centrati a (56, 56), (456, 56), (456, 456), (56, 456)
# La forma interna è matematicamente perfetta, 0 approssimazioni!
# -------------------------------------------------------------------------
svg_gemini = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <rect x="16" y="16" width="480" height="480" rx="112" fill="#0E121B" />
  <!-- Stella a 4 punte concava perfetta (R=150 da centro 256,256) -->
  <path d="M 256 106
           A 150 150 0 0 0 406 256
           A 150 150 0 0 0 256 406
           A 150 150 0 0 0 106 256
           A 150 150 0 0 0 256 106 Z"
        fill="#38BDF8" />
  <!-- Foro centrale geometrico: piccolo cerchio nero dello sfondo -->
  <circle cx="256" cy="256" r="28" fill="#0E121B" />
</svg>"""

# -------------------------------------------------------------------------
# 2. THE DISCORD-STYLE SYMMETRICAL GLYPH
# Rettangolo arrotondato puro con arco inferiore sottratto e Play centrale perfetto
# -------------------------------------------------------------------------
svg_discord = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <rect x="16" y="16" width="480" height="480" rx="112" fill="#0E121B" />
  <!-- Silhouette controller/visore simmetrica e pulita -->
  <path d="M 160 176
           L 352 176
           A 56 56 0 0 1 408 232
           L 408 280
           A 56 56 0 0 1 352 336
           L 320 336
           A 72 72 0 0 0 192 336
           L 160 336
           A 56 56 0 0 1 104 280
           L 104 232
           A 56 56 0 0 1 160 176 Z"
        fill="#6C5CE7" />
  <!-- Triangolo Play centrale equilatero ritagliato nello sfondo -->
  <polygon points="236,220 292,256 236,292" fill="#0E121B" />
</svg>"""

# -------------------------------------------------------------------------
# 3. THE STEAM-STYLE TANGENT LINK (Biella / Orologio-Play)
# Due cerchi perfetti (R1=90 a 200,256 e R2=45 a 330,256) collegati da tangenti rette
# -------------------------------------------------------------------------
svg_steam = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <rect x="16" y="16" width="480" height="480" rx="112" fill="#0E121B" />
  <!-- Sagoma Steam-style: cerchio grande (210, 256, R=95) + cerchio piccolo (340, 256, R=45) uniti -->
  <path d="M 210 161
           A 95 95 0 0 0 210 351
           L 340 301
           A 45 45 0 0 0 340 211
           L 210 161 Z"
        fill="#6C5CE7" />
  <!-- Foro centrale nel mozzo grande -->
  <circle cx="210" cy="256" r="48" fill="#0E121B" />
  <!-- Foro nel perno piccolo -->
  <circle cx="340" cy="256" r="20" fill="#0E121B" />
</svg>"""

# -------------------------------------------------------------------------
# 4. THE MINIMALIST "F-PLAY" (Geometria pura alla Google Wallet)
# Due barre verticali e una freccia orizzontale in viola e blu solido
# -------------------------------------------------------------------------
svg_wallet = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <rect x="16" y="16" width="480" height="480" rx="112" fill="#0E121B" />
  <!-- Cerchio grande parziale con spicchio a freccia Play ritagliato -->
  <!-- Oppure un anello puro con freccia Play -->
  <circle cx="256" cy="256" r="120" fill="none" stroke="#6C5CE7" stroke-width="40" />
  <!-- Freccia solida al centro che punta a destra -->
  <polygon points="230,200 310,256 230,312" fill="#38BDF8" />
</svg>"""

tests = [
    ("test_gemini_star.svg", svg_gemini),
    ("test_discord_glyph.svg", svg_discord),
    ("test_steam_crank.svg", svg_steam),
    ("test_ring_play.svg", svg_wallet),
]

for filename, content in tests:
    filepath = svg_dir / filename
    filepath.write_text(content)
    png_path = out_dir / filename.replace(".svg", ".png")
    subprocess.run(["resvg", "-w", "1024", "-h", "1024", str(filepath), str(png_path)], check=True)

