# AI Closet Design System

Source inspiration: Apple-style DESIGN.md from getdesign.md.

This file is the UI contract for the Flutter frontend. Use it whenever building screens, components, prompts for Google Stitch, or visual references for Antigravity.

## Product Feel

The app should feel like a quiet, premium wardrobe assistant:

- Spacious, image-first, and calm.
- Useful before it is decorative.
- Clear enough for a first-time user taking a clothing photo in a hurry.
- Polished enough to make saved clothing feel worth keeping.

Avoid playful clutter, heavy gradients, busy cards, and dense explanatory text. The first screen should show the actual wardrobe workflow, not a marketing landing page.

## Visual Principles

1. Let clothing photos lead the interface.
2. Keep backgrounds mostly neutral and bright.
3. Use black, white, gray, and one restrained accent color.
4. Prefer soft hierarchy over loud decoration.
5. Make AI output inspectable: tags, confidence, category, and edit actions must be easy to scan.
6. Every AI result should be editable by the user.

## Color Tokens

Use these as semantic tokens in Flutter instead of hard-coded colors.

```dart
class AppColors {
  static const ink = Color(0xFF111111);
  static const primaryText = Color(0xFF1D1D1F);
  static const secondaryText = Color(0xFF6E6E73);
  static const tertiaryText = Color(0xFF8E8E93);

  static const background = Color(0xFFFFFFFF);
  static const groupedBackground = Color(0xFFF5F5F7);
  static const elevated = Color(0xFFFFFFFF);
  static const separator = Color(0xFFE5E5EA);

  static const accent = Color(0xFF007AFF);
  static const success = Color(0xFF34C759);
  static const warning = Color(0xFFFF9500);
  static const danger = Color(0xFFFF3B30);

  static const tagBackground = Color(0xFFF2F2F7);
  static const cameraOverlay = Color(0x66000000);
}
```

## Typography

Prefer SF Pro on Apple platforms through Flutter's system font behavior.

- Large title: 34 / 41, weight 700
- Title 1: 28 / 34, weight 700
- Title 2: 22 / 28, weight 700
- Headline: 17 / 22, weight 600
- Body: 17 / 22, weight 400
- Callout: 16 / 21, weight 400
- Subheadline: 15 / 20, weight 400
- Footnote: 13 / 18, weight 400
- Caption: 12 / 16, weight 400

Do not scale text with viewport width. Use Flutter text themes and responsive layout constraints.

## Spacing

Use a 4-point spacing system:

- 4: tiny gaps
- 8: compact component gaps
- 12: related content spacing
- 16: default screen padding
- 20: section spacing
- 24: large grouping
- 32: major screen rhythm

## Shape

- Buttons: 12-16 radius depending on height.
- Cards and tiles: 8 radius by default.
- Bottom sheets: 24 top radius.
- Image thumbnails: 10-14 radius.
- Avoid nested cards.

## Core Components

### Clothing Tile

Use for wardrobe grid items.

- Image fills the tile.
- Category label appears below or in a subtle overlay.
- Tag count and favorite state may use icons.
- Tile dimensions must be stable with `AspectRatio`.

### AI Tag Chips

Use for Fashionpedia output and user-edited labels.

- Low-contrast gray background.
- One tag per chip.
- Editable tags should expose remove and add actions.
- Show low-confidence tags with a warning tint or review label.

### Camera Capture

The camera screen should be direct and low-friction.

- Full-screen camera preview.
- Bottom capture button.
- Gallery import action.
- Optional garment boundary guide.
- After capture, show review before saving.

### Classification Review

The classification result should never feel final without user control.

- Primary image preview.
- Category selector.
- Tag chips grouped by type: category, material, color, pattern, season, occasion.
- Confidence summary.
- Save button fixed near bottom.

### LLM Chat / Ask Closet

The chat should be grounded in wardrobe data.

- Show selected context: weather, occasion, available items, excluded items.
- Let the user ask natural language questions.
- Recommendations should include clothing item references and reasons.
- Provide "use this outfit", "swap item", and "why" actions.

## Screen Rules

### Home

Show a wardrobe summary, quick capture, and recent items. Do not start with a hero section.

### Closet

Image grid first. Filters should be compact and persistent:

- Category
- Color
- Season
- Occasion
- Recently added

### Add Item

Camera-first. AI results are a draft, not a command.

### Item Detail

Show the photo, editable metadata, outfit history, and similar items.

### Ask

Conversation-first, but keep recommended items visual.

## Accessibility

- Minimum tap target: 44x44.
- Text and important icons must meet contrast expectations.
- Do not rely on color alone for confidence or error states.
- All image-only actions need semantic labels.

## Flutter Implementation Notes

- Use `ThemeData` and extension tokens instead of scattering constants.
- Prefer Cupertino patterns where they improve platform feel, but keep app navigation consistent across iOS and Android.
- Use `CustomScrollView` and slivers for image-heavy screens.
- Use `AspectRatio` for grids to prevent layout shift.
- Cache network and local images.
- Design loading states for AI classification and LLM answers from the beginning.

