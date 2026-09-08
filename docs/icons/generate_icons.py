import math
import subprocess
from pathlib import Path

out_dir = Path("docs/icons")
svg_dir = out_dir / "svg"
svg_dir.mkdir(parents=True, exist_ok=True)

# -------------------------------------------------------------
# 1. THE ECLIPSE ORBIT (L'Orbita del Tempo)
# An open celestial time arc embracing an offset floating focal core
# -------------------------------------------------------------
svg1 = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <!-- Background Gradient -->
    <radialGradient id="bg1" cx="50%" cy="35%" r="70%">
      <stop offset="0%" stop-color="#181F2E" />
      <stop offset="60%" stop-color="#0F131E" />
      <stop offset="100%" stop-color="#080A10" />
    </radialGradient>
    
    <!-- Outer Arc Gradient (Purple to Cyan) -->
    <linearGradient id="arcGrad" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#5E43F3" />
      <stop offset="50%" stop-color="#7B61FF" />
      <stop offset="100%" stop-color="#4ECAFF" />
    </linearGradient>

    <!-- Inner Core Gradient -->
    <linearGradient id="coreGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#56CCF2" />
      <stop offset="100%" stop-color="#6C5CE7" />
    </linearGradient>
    
    <!-- Subtle glow filter -->
    <filter id="softGlow" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="16" result="blur" />
      <feComposite in="SourceGraphic" in2="blur" operator="over" />
    </filter>
  </defs>

  <!-- Background Squircle -->
  <rect x="16" y="16" width="480" height="480" rx="112" ry="112" fill="url(#bg1)" stroke="#222B3D" stroke-width="2.5" />
  
  <!-- Subtle ambient inner back-glow -->
  <circle cx="256" cy="256" r="140" fill="#6C5CE7" opacity="0.08" filter="url(#softGlow)" />

  <!-- Outer Orbital Progress Arc (Radius 145, 270 degree sweep) -->
  <!-- Arc from 135 deg to 45 deg clockwise -->
  <path d="M 153.46 358.54
           A 145 145 0 1 1 358.54 358.54"
        fill="none"
        stroke="url(#arcGrad)"
        stroke-width="32"
        stroke-linecap="round" />

  <!-- Inner floating crescent / aperture core -->
  <g transform="translate(256, 256)">
    <!-- Satellite milestone pulse -->
    <circle cx="0" cy="145" r="16" fill="#4ECAFF" />
    <circle cx="0" cy="145" r="8" fill="#FFFFFF" />

    <!-- Focal geometric core: an elegant offset sphere with an angled aperture facet -->
    <circle cx="0" cy="0" r="76" fill="#131722" stroke="#252D3F" stroke-width="3" />
    <!-- Dynamic forward chevron blade nested in center -->
    <path d="M -24 -46 L 42 0 L -24 46 Z"
          fill="url(#coreGrad)"
          stroke="#4ECAFF"
          stroke-width="2"
          stroke-linejoin="round" />
  </g>
</svg>
"""

# -------------------------------------------------------------
# 2. THE GEOMETRIC APERTURE (L'Apertura / Il Prisma)
# 3 elegant curved satin facets forming a lens/prism with negative-space play
# -------------------------------------------------------------
svg2 = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <radialGradient id="bg2" cx="50%" cy="30%" r="75%">
      <stop offset="0%" stop-color="#161A26" />
      <stop offset="60%" stop-color="#0E1119" />
      <stop offset="100%" stop-color="#07090E" />
    </radialGradient>

    <!-- Blade 1 Gradient: Deep Amethyst to Royal Purple -->
    <linearGradient id="b1Grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#7C5CFC" />
      <stop offset="100%" stop-color="#4C34D3" />
    </linearGradient>

    <!-- Blade 2 Gradient: Electric Violet to Cyan -->
    <linearGradient id="b2Grad" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#5B45F5" />
      <stop offset="100%" stop-color="#38C6F4" />
    </linearGradient>

    <!-- Blade 3 Gradient: Luminous Cerulean Cyan -->
    <linearGradient id="b3Grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#46D3F9" />
      <stop offset="100%" stop-color="#2D8FF7" />
    </linearGradient>

    <filter id="bladeShadow" x="-20%" y="-20%" width="150%" height="150%">
      <feDropShadow dx="0" dy="8" stdDeviation="12" flood-color="#000000" flood-opacity="0.5" />
    </filter>
  </defs>

  <!-- Squircle Background -->
  <rect x="16" y="16" width="480" height="480" rx="112" ry="112" fill="url(#bg2)" stroke="#232A3B" stroke-width="2.5" />

  <!-- Aperture Composition centered at (256, 256) -->
  <g transform="translate(256, 256)">
    <!-- Ambient back glow -->
    <circle cx="0" cy="0" r="130" fill="#6C5CE7" opacity="0.09" />

    <!-- Blade 1 (Top/Left) -->
    <path d="M -110 -80 C -40 -150, 60 -150, 130 -90 L 20 -20 C -20 -50, -60 -60, -110 -80 Z"
          fill="url(#b1Grad)"
          filter="url(#bladeShadow)" />

    <!-- Blade 2 (Bottom/Left) -->
    <path d="M -90 120 C -150 50, -150 -50, -90 -120 L -20 0 C -40 40, -40 80, -90 120 Z"
          fill="url(#b2Grad)"
          filter="url(#bladeShadow)" />

    <!-- Blade 3 (Right Wing - Forward Aperture) -->
    <path d="M 120 -60 C 160 10, 150 110, 80 150 L 0 20 C 40 10, 80 -10, 120 -60 Z"
          fill="url(#b3Grad)"
          filter="url(#bladeShadow)" />

    <!-- Central Floating Diamond/Facet: Minimalist focal jewel -->
    <polygon points="12,-28 48,0 12,28 -16,0" fill="#FFFFFF" opacity="0.95" />
  </g>
</svg>
"""

# -------------------------------------------------------------
# 3. THE LEISURE RIBBON / INFINITY FLOW (Il Nastro Fluido)
# An aerodynamic continuous loop in isometric perspective
# -------------------------------------------------------------
svg3 = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <radialGradient id="bg3" cx="50%" cy="30%" r="80%">
      <stop offset="0%" stop-color="#171A24" />
      <stop offset="70%" stop-color="#0E1017" />
      <stop offset="100%" stop-color="#06070B" />
    </radialGradient>

    <!-- Top Ribbon Arc -->
    <linearGradient id="ribbonTop" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#7B61FF" />
      <stop offset="50%" stop-color="#6049F7" />
      <stop offset="100%" stop-color="#4ECAFF" />
    </linearGradient>

    <!-- Bottom Ribbon Arc -->
    <linearGradient id="ribbonBottom" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#3D2DBB" />
      <stop offset="60%" stop-color="#5842EC" />
      <stop offset="100%" stop-color="#46C5F8" />
    </linearGradient>

    <filter id="ribbonDepth" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="10" stdDeviation="16" flood-color="#000000" flood-opacity="0.6" />
    </filter>
  </defs>

  <!-- Squircle Background -->
  <rect x="16" y="16" width="480" height="480" rx="112" ry="112" fill="url(#bg3)" stroke="#222838" stroke-width="2.5" />

  <g transform="translate(256, 256)" filter="url(#ribbonDepth)">
    <!-- Back loop segment -->
    <path d="M -110 -40 C -110 -110, -30 -130, 40 -80 L 120 0 C 140 20, 140 50, 110 80 L 30 130 C -40 160, -110 110, -110 40 Z"
          fill="none"
          stroke="url(#ribbonBottom)"
          stroke-width="44"
          stroke-linecap="round"
          stroke-linejoin="round" />

    <!-- Forward loop cross that forms an elegant dynamic wedge -->
    <path d="M -70 -70 L 80 0 L -70 70"
          fill="none"
          stroke="url(#ribbonTop)"
          stroke-width="36"
          stroke-linecap="round"
          stroke-linejoin="round" />

    <!-- Sleek inner light core -->
    <circle cx="80" cy="0" r="10" fill="#FFFFFF" />
  </g>
</svg>
"""

# -------------------------------------------------------------
# 4. THE KINETIC MONOGRAM (Il Monogramma Architettonico)
# Modernist precision: pause tracks meeting a forward horizon chevron
# -------------------------------------------------------------
svg4 = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <radialGradient id="bg4" cx="50%" cy="30%" r="80%">
      <stop offset="0%" stop-color="#181B26" />
      <stop offset="60%" stop-color="#0F111A" />
      <stop offset="100%" stop-color="#08090D" />
    </radialGradient>

    <!-- Vertical Bar 1 (Royal Violet) -->
    <linearGradient id="bar1Grad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#846BFF" />
      <stop offset="100%" stop-color="#553DEF" />
    </linearGradient>

    <!-- Vertical Bar 2 (Violet to Cyan) -->
    <linearGradient id="bar2Grad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#6C5CE7" />
      <stop offset="100%" stop-color="#4CB8F6" />
    </linearGradient>

    <!-- Forward Chevron (Electric Cyan Highlight) -->
    <linearGradient id="chevGrad" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#56CCF2" />
      <stop offset="100%" stop-color="#3B82F6" />
    </linearGradient>

    <filter id="softElevation" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="8" stdDeviation="14" flood-color="#000000" flood-opacity="0.45" />
    </filter>
  </defs>

  <!-- Squircle Background -->
  <rect x="16" y="16" width="480" height="480" rx="112" ry="112" fill="url(#bg4)" stroke="#232738" stroke-width="2.5" />

  <!-- Composition centered at (256, 256) -->
  <g transform="translate(256, 256)" filter="url(#softElevation)">
    <!-- Ambient subtle halo -->
    <circle cx="20" cy="0" r="120" fill="#6C5CE7" opacity="0.07" />

    <!-- Left Anchor Pillar (Pause / Work Baseline, rounded pill) -->
    <rect x="-115" y="-110" width="42" height="220" rx="21" ry="21" fill="url(#bar1Grad)" />

    <!-- Center Bridge Pillar (Tracking / Progression) -->
    <rect x="-45" y="-75" width="42" height="150" rx="21" ry="21" fill="url(#bar2Grad)" />

    <!-- Dynamic Forward Chevron (Leisure / Play / Future) -->
    <path d="M 25 -95
             C 32 -103, 45 -103, 53 -95
             L 135 -15
             C 145 -5, 145 10, 135 20
             L 53 100
             C 45 108, 32 108, 25 100
             C 17 92, 17 79, 25 71
             L 95 2
             L 25 -66
             C 17 -74, 17 -87, 25 -95 Z"
          fill="url(#chevGrad)" />
  </g>
</svg>
"""

svgs = [
    ("concept_e1_eclipse_orbit.svg", svg1),
    ("concept_e2_geometric_aperture.svg", svg2),
    ("concept_e3_leisure_ribbon.svg", svg3),
    ("concept_e4_kinetic_monogram.svg", svg4),
]

for filename, content in svgs:
    filepath = svg_dir / filename
    filepath.write_text(content)
    png_path = out_dir / filename.replace(".svg", ".png")
    # Render with resvg to 1024x1024
    subprocess.run(["resvg", "-w", "1024", "-h", "1024", str(filepath), str(png_path)], check=True)
    print(f"Rendered {png_path}")

