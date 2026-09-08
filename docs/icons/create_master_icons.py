from PIL import Image, ImageDraw, ImageFilter
import numpy as np

img = Image.open("/home/tms/.gemini/antigravity-cli/brain/946b476b-8a64-4f8b-b87c-ba0b8058d135/.user_uploaded/uploaded_media_1788892133100.png").convert("RGBA")
arr = np.array(img)

# Squircle bounds: X [323, 700], Y [97, 475]
# Let's crop the squircle with a tiny 1px margin
xmin, xmax = 323, 700
ymin, ymax = 97, 475

# 1. Master Squircle Icon: Crop the squircle and resize cleanly with Lanczos to 1024x1024
# First let's remove any surrounding grey pixels outside the squircle rounded corners by applying an alpha mask
squircle_crop = img.crop((xmin, ymin, xmax, ymax)).resize((1024, 1024), Image.Resampling.LANCZOS)

# Create a clean continuous curvature mask for 1024x1024
mask_img = Image.new("L", (1024, 1024), 0)
draw = ImageDraw.Draw(mask_img)
draw.rounded_rectangle([0, 0, 1024, 1024], radius=230, fill=255)
# Composite with dark background
master_squircle = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
master_squircle.paste(squircle_crop, (0, 0), mask_img)
master_squircle.save("docs/icons/app_icon_squircle_1024.png")

# 2. Full-bleed Master Icon for Android / iOS:
# Fill 1024x1024 with the exact dark background (#0E1117)
# And place the glyph centered with perfect safe-zone margins (scaled to ~600px width)
# Let's crop the glyph itself (the controller + play triangle)
# Find glyph pixels: pixels inside squircle that are bright (R > 50 or G > 50 or B > 50)
glyph_mask = (arr[ymin:ymax, xmin:xmax, 0] > 45) | (arr[ymin:ymax, xmin:xmax, 1] > 45) | (arr[ymin:ymax, xmin:xmax, 2] > 70)
gy, gx = np.where(glyph_mask)
g_ymin, g_ymax = gy.min(), gy.max()
g_xmin, g_xmax = gx.min(), gx.max()
print(f"Glyph bounding box within squircle: X [{g_xmin}, {g_xmax}], Y [{g_ymin}, {g_ymax}]")

# Crop the glyph with surrounding dark background to preserve anti-aliasing
glyph_crop = img.crop((xmin + g_xmin - 15, ymin + g_ymin - 15, xmin + g_xmax + 15, ymin + g_ymax + 15))

# Target size in 1024x1024: roughly 620px width for safe zone
glyph_aspect = glyph_crop.width / glyph_crop.height
target_w = 640
target_h = int(target_w / glyph_aspect)
glyph_resized = glyph_crop.resize((target_w, target_h), Image.Resampling.LANCZOS)

# Background color sampled from dark area: (14, 17, 23)
bg_color = (14, 17, 23, 255)
full_bleed = Image.new("RGBA", (1024, 1024), bg_color)
paste_x = (1024 - target_w) // 2
paste_y = (1024 - target_h) // 2
full_bleed.paste(glyph_resized, (paste_x, paste_y))
full_bleed.save("docs/icons/app_icon_full_bleed_1024.png")

print("Created docs/icons/app_icon_squircle_1024.png and docs/icons/app_icon_full_bleed_1024.png")
