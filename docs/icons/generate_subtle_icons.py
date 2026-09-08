import subprocess
from pathlib import Path

out_dir = Path("docs/icons")
svg_dir = out_dir / "svg"
svg_dir.mkdir(parents=True, exist_ok=True)

# -------------------------------------------------------------
# PROPOSTA A: L'Intersezione di Due Schermi (Dual Horizon)
# Due lamine geometriche traslucide che incrociandosi creano la freccia Play
# -------------------------------------------------------------
svg_a = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <radialGradient id="bgA" cx="50%" cy="30%" r="75%">
      <stop offset="0%" stop-color="#141824" />
      <stop offset="60%" stop-color="#0D1017" />
      <stop offset="100%" stop-color="#07080D" />
    </radialGradient>

    <!-- Lamina Superiore (Viola Ametista) -->
    <linearGradient id="beamPurple" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#7C5CFC" stop-opacity="0.9" />
      <stop offset="100%" stop-color="#4F36E2" stop-opacity="0.75" />
    </linearGradient>

    <!-- Lamina Inferiore (Ciano Ghiaccio) -->
    <linearGradient id="beamCyan" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#38BDF8" stop-opacity="0.9" />
      <stop offset="100%" stop-color="#0284C7" stop-opacity="0.75" />
    </linearGradient>

    <!-- Prisma d'Intersezione Luminoso -->
    <linearGradient id="prismGrad" x1="0%" y1="50%" x2="100%" y2="50%">
      <stop offset="0%" stop-color="#8B5CF6" />
      <stop offset="50%" stop-color="#A78BFA" />
      <stop offset="100%" stop-color="#38BDF8" />
    </linearGradient>

    <filter id="softShadowA" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="12" stdDeviation="16" flood-color="#000000" flood-opacity="0.55" />
    </filter>
  </defs>

  <!-- Squircle Canvas -->
  <rect x="16" y="16" width="480" height="480" rx="112" ry="112" fill="url(#bgA)" stroke="#1F2637" stroke-width="2" />

  <g transform="translate(256, 256)" filter="url(#softShadowA)">
    <!-- Luce d'ambiente centrale molto tenue -->
    <circle cx="10" cy="0" r="110" fill="#6366F1" opacity="0.06" />

    <!-- Lamina 1 (Inclinata dall'alto a sinistra verso il centro-destra) -->
    <path d="M -130 -110 
             C -130 -110, -50 -130, 20 -70 
             L 110 -10
             C 125 0, 125 15, 110 25
             L 0 -55
             C -60 -95, -110 -85, -130 -110 Z"
          fill="url(#beamPurple)" />

    <!-- Lamina 2 (Inclinata dal basso a sinistra verso il centro-destra) -->
    <path d="M -130 110 
             C -130 110, -50 130, 20 70 
             L 110 10
             C 125 0, 125 -15, 110 -25
             L 0 55
             C -60 95, -110 85, -130 110 Z"
          fill="url(#beamCyan)" />

    <!-- Nucleo centrale a cuspide: dove i due fasci si fondono nel tasto di avvio -->
    <path d="M -45 -60
             L 65 0
             L -45 60
             C -55 50, -55 -50, -45 -60 Z"
          fill="url(#prismGrad)"
          opacity="0.95" />

    <!-- Sottile linea di luce sul vertice di avanzamento -->
    <line x1="-35" y1="-45" x2="60" y2="0" stroke="#FFFFFF" stroke-width="2.5" opacity="0.4" stroke-linecap="round" />
  </g>
</svg>
"""

# -------------------------------------------------------------
# PROPOSTA B: I Tre Gradini / The Stepped Horizon (Play / F)
# 3 barre calibrate che nell'estremità destra formano il triangolo Play
# -------------------------------------------------------------
svg_b = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <radialGradient id="bgB" cx="50%" cy="30%" r="75%">
      <stop offset="0%" stop-color="#151926" />
      <stop offset="60%" stop-color="#0E111A" />
      <stop offset="100%" stop-color="#07080E" />
    </radialGradient>

    <!-- Barra 1: Viola Notte -->
    <linearGradient id="bar1" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#7C5CFC" />
      <stop offset="100%" stop-color="#6047EC" />
    </linearGradient>

    <!-- Barra 2: Transizione Indaco-Ciano (Vertice del Play) -->
    <linearGradient id="bar2" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#6047EC" />
      <stop offset="60%" stop-color="#4F75F8" />
      <stop offset="100%" stop-color="#38BDF8" />
    </linearGradient>

    <!-- Barra 3: Ciano Puro Compatto -->
    <linearGradient id="bar3" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#38BDF8" />
      <stop offset="100%" stop-color="#0EA5E9" />
    </linearGradient>

    <filter id="softShadowB" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="8" stdDeviation="12" flood-color="#000000" flood-opacity="0.5" />
    </filter>
  </defs>

  <!-- Squircle Canvas -->
  <rect x="16" y="16" width="480" height="480" rx="112" ry="112" fill="url(#bgB)" stroke="#21283B" stroke-width="2" />

  <g transform="translate(256, 256)" filter="url(#softShadowB)">
    <!-- Barra Superiore (Y: -80, Altezza 44, da X=-120 a X=40) -->
    <rect x="-125" y="-82" width="180" height="44" rx="22" ry="22" fill="url(#bar1)" />

    <!-- Barra Centrale (Y: -22, Altezza 44, da X=-125 a X=115 -> sporge in avanti!) -->
    <rect x="-125" y="-22" width="245" height="44" rx="22" ry="22" fill="url(#bar2)" />

    <!-- Barra Inferiore (Y: +38, Altezza 44, da X=-125 a X=40 -> allineata con la superiore) -->
    <rect x="-125" y="38" width="180" height="44" rx="22" ry="22" fill="url(#bar3)" />

    <!-- Il tocco subtle: Le tre punte delle barre (40, 115, 40) disegnano un triangolo Play perfetto -->
    <!-- Un accento circolare sul vertice di avanzamento -->
    <circle cx="95" cy="0" r="7" fill="#FFFFFF" opacity="0.9" />
  </g>
</svg>
"""

# -------------------------------------------------------------
# PROPOSTA C: Il Segnalibro di Luce (The Prismatic Bookmark)
# Una linguetta geometrica a due sfaccettature che tiene il segno nel tempo
# -------------------------------------------------------------
svg_c = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <radialGradient id="bgC" cx="50%" cy="30%" r="75%">
      <stop offset="0%" stop-color="#141722" />
      <stop offset="60%" stop-color="#0E1018" />
      <stop offset="100%" stop-color="#06070B" />
    </radialGradient>

    <!-- Faccia Sinistra del Segnalibro: Viola Notte -->
    <linearGradient id="bookLeft" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#7B61FF" />
      <stop offset="100%" stop-color="#4834D4" />
    </linearGradient>

    <!-- Faccia Destra del Segnalibro: Ciano Satinato -->
    <linearGradient id="bookRight" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#38BDF8" />
      <stop offset="100%" stop-color="#0284C7" />
    </linearGradient>

    <filter id="bookmarkShadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="14" stdDeviation="16" flood-color="#000000" flood-opacity="0.6" />
    </filter>
  </defs>

  <!-- Squircle Canvas -->
  <rect x="16" y="16" width="480" height="480" rx="112" ry="112" fill="url(#bgC)" stroke="#1F2536" stroke-width="2" />

  <g transform="translate(256, 256)" filter="url(#bookmarkShadow)">
    <!-- Faccia Sinistra (Viola) -->
    <path d="M -64 -140
             L 0 -140
             L 0 70
             L -64 30
             Z"
          fill="url(#bookLeft)" />

    <!-- Faccia Destra (Ciano) - termina con un'angolatura dinamica verso destra -->
    <path d="M 0 -140
             L 64 -140
             L 64 30
             L 0 70
             Z"
          fill="url(#bookRight)" />

    <!-- Cuspide inferiore che forma la punta a freccia del Play/Segnalibro -->
    <polygon points="0,70 64,30 85,75 0,120 -20,80" fill="#38BDF8" opacity="0.85" />

    <!-- Sottile linea di piega centrale satinata -->
    <line x1="0" y1="-140" x2="0" y2="120" stroke="#FFFFFF" stroke-width="1.8" opacity="0.5" />

    <!-- Una fessura orizzontale in alto (l'asola del segnalibro) -->
    <rect x="-35" y="-105" width="70" height="12" rx="6" ry="6" fill="#0E1018" opacity="0.75" />
  </g>
</svg>
"""

# -------------------------------------------------------------
# PROPOSTA D: La Fessura / The Light Slit (Minimalismo Radicale)
# Taglio geometrico a cuneo da cui trapela luce pura viola-ciano
# -------------------------------------------------------------
svg_d = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <radialGradient id="bgD" cx="50%" cy="30%" r="75%">
      <stop offset="0%" stop-color="#141722" />
      <stop offset="60%" stop-color="#0B0E15" />
      <stop offset="100%" stop-color="#06070B" />
    </radialGradient>

    <!-- Gradiente della fessura di luce (Viola intenso a Ciano puro) -->
    <linearGradient id="slitGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#8B5CF6" />
      <stop offset="45%" stop-color="#6366F1" />
      <stop offset="100%" stop-color="#38BDF8" />
    </linearGradient>

    <filter id="slitDepth" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="6" stdDeviation="8" flood-color="#000000" flood-opacity="0.7" />
    </filter>
  </defs>

  <!-- Squircle Canvas Monolitico -->
  <rect x="16" y="16" width="480" height="480" rx="112" ry="112" fill="url(#bgD)" stroke="#1D2332" stroke-width="2" />

  <g transform="translate(256, 256)">
    <!-- Scanalatura scura in bassorilievo (ombra interna della fessura) -->
    <path d="M -50 -90
             L 65 0
             L -50 90"
          fill="none"
          stroke="#05070A"
          stroke-width="38"
          stroke-linecap="round"
          stroke-linejoin="round" />

    <!-- La lama di luce viva all'interno del taglio -->
    <path d="M -50 -90
             L 65 0
             L -50 90"
          fill="none"
          stroke="url(#slitGrad)"
          stroke-width="22"
          stroke-linecap="round"
          stroke-linejoin="round"
          filter="url(#slitDepth)" />

    <!-- Filo di luce bianca al centro del vertice -->
    <circle cx="65" cy="0" r="5" fill="#FFFFFF" opacity="0.9" />

    <!-- Punto di ancoraggio/origine sulla sinistra (richiama il tracking / l'inizio del percorso) -->
    <circle cx="-100" cy="0" r="11" fill="#38BDF8" opacity="0.85" />
    <circle cx="-100" cy="0" r="4" fill="#FFFFFF" />
  </g>
</svg>
"""

subtle_icons = [
    ("concept_s1_dual_horizon.svg", svg_a),
    ("concept_s2_stepped_horizon.svg", svg_b),
    ("concept_s3_prismatic_bookmark.svg", svg_c),
    ("concept_s4_light_slit.svg", svg_d),
]

for filename, content in subtle_icons:
    filepath = svg_dir / filename
    filepath.write_text(content)
    png_path = out_dir / filename.replace(".svg", ".png")
    subprocess.run(["resvg", "-w", "1024", "-h", "1024", str(filepath), str(png_path)], check=True)
    print(f"Rendered {png_path}")

