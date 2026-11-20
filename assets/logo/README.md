# NH Digital Official Branding & Logo Assets

This directory hosts brand assets for **NH Win Debloater** and **NH Digital** ([https://nhdigital.shop](https://nhdigital.shop)).

---

## Supported Brand Files

Once you obtain your official logo files from **[nhdigital.shop](https://nhdigital.shop)**, place them directly into this folder using any of the supported filenames below:

| File Name | Purpose | Recommended Resolution / Format |
| :--- | :--- | :--- |
| **`logo.png`** | Primary header logo and application icon | Transparent PNG (e.g. 512x512 or 800x240 horizontal) |
| **`logo.ico`** | Windows application window & taskbar icon | Multi-resolution Windows Icon (.ico, 16x16 to 256x256) |
| **`nhdigital-logo.png`** | Alternative horizontal brand banner | Transparent PNG (e.g. 600x180) |
| **`nh-digital-logo.svg`** | Vector fallback graphic | Clean SVG format (shipped by default) |

---

## Automatic Rendering & Fallback Logic

The WPF Guided Assistant (`src/UI/AppController.ps1`) automatically scans this directory on startup:
1. **Window Icon:** Checks for `logo.ico`, `favicon.ico`, or `logo.png` and applies it to the title bar and taskbar.
2. **Header Logo:** Checks for `logo.png`, `nhdigital-logo.png`, or `logo.jpg` with DPI-safe uniform scaling.
3. **Graceful Fallback:** If custom raster images are not present, the assistant displays a built-in vector badge with the **NH Digital** monogram and typography.
