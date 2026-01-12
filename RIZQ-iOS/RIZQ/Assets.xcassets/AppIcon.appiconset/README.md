# RIZQ App Icon Requirements

## What You Need

Create a file named `AppIcon.png` in this folder with these specifications:

| Property | Requirement |
|----------|-------------|
| **Size** | 1024 x 1024 pixels (exactly) |
| **Format** | PNG |
| **Transparency** | ❌ NOT allowed (must have solid background) |
| **Corners** | Square (iOS automatically rounds them) |

## Design Suggestions for RIZQ

Based on the app's Islamic dua practice theme:

**Color Palette (from brand):**
- Warm Sand: `#D4A574` (primary)
- Deep Mocha: `#6B4423` (accent)
- Warm Cream: `#F5EFE7` (background)
- Soft Gold: `#E6C79C`

**Icon Concepts:**
1. **Hands in Dua** - Open palms raised in supplication
2. **Crescent & Star** - Classic Islamic motif
3. **Prayer Beads** - Tasbih/misbaha
4. **Arabic Calligraphy** - "رزق" (Rizq) in elegant script
5. **Sunrise/Sunset** - Representing prayer times

**AI Prompt Example:**
> "App icon for an Islamic dua (supplication) practice app called RIZQ. Minimalist design with warm sand and deep mocha colors. Feature raised hands in prayer position or elegant Arabic calligraphy. No text except optional Arabic. Solid warm cream or deep mocha background. Modern, warm, spiritual feel. 1024x1024 pixels, square format, no transparency."

## How to Add Your Icon

1. Generate or create your 1024x1024 PNG icon
2. Rename it to `AppIcon.png`
3. Place it in this folder (`AppIcon.appiconset/`)
4. Rebuild the project

## Verify

After adding the icon, run:
```bash
cd RIZQ-iOS && xcodebuild -scheme RIZQ build
```

The build should succeed with the new icon included.
