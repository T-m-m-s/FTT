from PIL import Image, ImageDraw

# 1. Standard master icon with filled dark background (for iOS & legacy Android & web)
# Take app_icon_squircle_1024, but place it on a solid background matching its edge (#0C0F16)
base_tile = Image.open("docs/icons/app_icon_squircle_1024.png").convert("RGBA")

# Let's inspect the corner color of the squircle
# Edge color is approximately (14, 17, 23)
solid_bg = (12, 15, 22, 255)

# A master icon that fills 1024x1024 completely
master_icon = Image.new("RGBA", (1024, 1024), solid_bg)
# Center the tile (scale slightly so it has nice padding or fills 92% of the canvas)
tile_resized = base_tile.resize((940, 940), Image.Resampling.LANCZOS)
master_icon.paste(tile_resized, (42, 42), tile_resized)
master_icon.save("docs/icons/app_icon_master_1024.png")

# 2. Foreground for Android Adaptive Icon (Safe zone: centered inside 66% circle, radius ~330px from center)
# The adaptive icon needs the glyph to be well within the safe zone (center 680x680)
adaptive_fg = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
# Let's scale the tile to 740x740 so even on a Pixel circular cut, the squircle fits cleanly or the glyph is centered
tile_safe = base_tile.resize((740, 740), Image.Resampling.LANCZOS)
adaptive_fg.paste(tile_safe, (142, 142), tile_safe)
adaptive_fg.save("docs/icons/app_icon_adaptive_foreground.png")

print("Created docs/icons/app_icon_master_1024.png and docs/icons/app_icon_adaptive_foreground.png")
