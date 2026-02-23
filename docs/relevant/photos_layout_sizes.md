# Media Layout & Sizing Spec (Mobile)

Author: Product/UX
Version: 1.0
Scope: Memory screen (covers + grid), camera/import pipeline, and image derivatives for mobile.

---

## 1) Terminology
- **Cover**: One of up to three featured photos at the top of a Memory. Ranked by votes.
- **Grid**: The gallery below the covers with all photos/videos.
- **Orientation**: `V` = portrait (vertical), `H` = landscape (horizontal).
- **Tile**: A rendered media cell in a grid. Uses center-crop unless otherwise noted.
- **Container**: The layout area that holds the cover mosaic.

---

## 2) Cover Mosaic (Top)
### 2.1 Container
- **Grid**: 4 columns × 2 rows of equal square cells.
- **Padding**: 16 px (left/right).
- **Gap**: 8 px (between tiles).
- **Height**: Target ~40% of the device viewport (max 48%).
- **Cell width**: `colW = floor((containerW - padding*2 - gap*3) / 4)`.

### 2.2 Tile sizes
- **V (portrait)**: `1×2` cells → `w = colW`, `h = colW*2 + gap`.
- **H (landscape)**: `2×1` cells → `w = colW*2 + gap`, `h = colW`.
- **B (big / hero)**: `2×2` cells → `w = colW*2 + gap`, `h = colW*2 + gap`.
- **Crop**: `object-fit: cover` with center focal point.
- **Max covers**: 3. Do not repeat these items again in the Grid section.

### 2.3 Placement rules (deterministic)
Order covers by votes (tie-breakers: prefer portrait → newer timestamp).

**1 cover**
- `[V]` or `[H]` → place as `B` centered (cols 2–3, rows 1–2).

**2 covers**
- `[V, H]` → `V` (col 1, rows 1–2) + `H` (cols 2–3, row 1).
- `[H, V]` → `H` (cols 1–2, row 1) + `V` (col 4, rows 1–2).
- `[V, V]` → `B` (cols 1–2, rows 1–2) + `V` (col 4, rows 1–2).
- `[H, H]` → `H` (cols 1–2, row 1) + `H` (cols 3–4, row 1)`.

**3 covers**
- `[V, H, H]` → `V` (col 1, rows 1–2) + `H` (cols 2–3, row 1) + `H` (cols 2–3, row 2).
- `[H, V, H]` → `H` (cols 1–2, row 1) + `V` (col 4, rows 1–2) + `H` (cols 1–2, row 2).
- `[H, H, V]` → `H` (cols 1–2, row 1) + `H` (cols 3–4, row 1) + `V` (col 4, rows 1–2).
- `[V, V, H]` → `V` (col 1, rows 1–2) + `V` (col 2, rows 1–2) + `H` (cols 3–4, row 2).
- `[V, V, V]` → `B` (cols 1–2, rows 1–2) + `V` (col 3, rows 1–2) + `V` (col 4, rows 1–2).
- `[H, H, H]` → `H` (cols 1–2, row 1) + `H` (cols 3–4, row 1) + `H` (cols 1–4, row 2).

**Notes**
- When only one cover is present, always use `B`.

---

## 3) Grid (All Photos)
### 3.1 Columns & spacing
- **Columns**: 3 in portrait (use 2 on very small screens); padding 16 px; gap 8 px.
- **Column width**: `colW = floor((screenW - padding*2 - gap*2) / 3)`.

### 3.2 Tile aspect ratios
- **Portrait**: **4:5** → `tileH = colW * 5/4`.
- **Landscape**: **16:9** spanning **2 columns** →
  - `spanW = colW*2 + gap`
  - `tileH = spanW * 9/16`
- **Square**: **1:1** for assets with ambiguous aspect ratios.
- **Crop**: center-crop; avoid letterboxing.

### 3.3 Ordering & clustering
- Sort by **capture timestamp**.
- Do **not** include cover items again in this grid.

---

## 4) Image/Video Derivatives (Storage & Delivery)
Keep the original upload and generate downscaled derivatives:

| Purpose | Max long edge |
|---|---|
| **LQIP / placeholder** | 64–128 px |
| **Grid tiles** | **512 px** |
| **Cover mosaic** | **1024 px** |
| **Viewer / share** | **2048 px** |

Guidelines:
- Do not upscale beyond the source.
- Use progressive/lazy loading with LQIP/blurhash.
- Prefetch ±12 upcoming thumbnails in the grid; ±3 in the viewer.

---

## 5) Camera & Import Handling
- Accept any source aspect ratio; **normalize at render time** using the rules above.
- Preferred capture guides:
  - **Portrait**: encourage **4:5** frame guide (most feed-friendly, less vertical scroll).
  - **Landscape**: 16:9.
- Save EXIF orientation and capture timestamp; use capture time for grid ordering.
- On import, extract EXIF; if missing, fall back to file modified time.

---

## 6) Pseudocode Cheatsheet
```pseudo
// Cover mosaic container
colW = floor((containerW - 16*2 - 8*3) / 4)
V = { w: colW,        h: colW*2 + 8 }      // 1×2
H = { w: colW*2 + 8,  h: colW }            // 2×1
B = { w: colW*2 + 8,  h: colW*2 + 8 }      // 2×2

// Grid tiles
colW = floor((screenW - 16*2 - 8*2) / 3)
portraitH  = colW * 5/4
landSpanW  = colW*2 + 8
landscapeH = landSpanW * 9/16
```


