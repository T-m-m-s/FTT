from PIL import Image, ImageFilter
import numpy as np

img = Image.open("/home/tms/.gemini/antigravity-cli/brain/946b476b-8a64-4f8b-b87c-ba0b8058d135/.user_uploaded/uploaded_media_1788892133100.png").convert("RGBA")
w, h = img.size
print(f"Original size: {w}x{h}")

# The background outside the icon is grey (around (120, 120, 125))
# The dark squircle has pixels with R,G,B < 35
arr = np.array(img)
# Find pixels that belong to the dark tile (e.g. brightness < 50)
mask = (arr[:, :, 0] < 40) & (arr[:, :, 1] < 40) & (arr[:, :, 2] < 40)

# Find coordinates of mask
y_indices, x_indices = np.where(mask)
ymin, ymax = y_indices.min(), y_indices.max()
xmin, xmax = x_indices.min(), x_indices.max()

print(f"Detected squircle bounds: X [{xmin}, {xmax}], Y [{ymin}, {ymax}], Width: {xmax-xmin}, Height: {ymax-ymin}")

# Center of squircle:
cx = (xmin + xmax) // 2
cy = (ymin + ymax) // 2
print(f"Center: ({cx}, {cy})")

# Sample background color of the squircle near the corners but inside the tile:
tile_bg = arr[ymin + 50, xmin + 50][:3]
print(f"Squircle background color: {tile_bg}")

# Let's crop a square centered around (cx, cy)
side = max(xmax - xmin, ymax - ymin)
# add a small margin if within bounds
margin = 2
crop_x1 = max(0, cx - side//2 - margin)
crop_x2 = min(w, cx + side//2 + margin)
crop_y1 = max(0, cy - side//2 - margin)
crop_y2 = min(h, cy + side//2 + margin)

cropped = img.crop((crop_x1, crop_y1, crop_x2, crop_y2))
cropped.save("docs/icons/cropped_raw.png")
print(f"Cropped raw saved: {cropped.size}")
