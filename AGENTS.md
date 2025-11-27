# Escanor Player – Agent Brief

Escanor Player is a premium media player inspired by Infuse — sleek, cinematic, and effortless.  
It plays **local videos, network shares (SMB / FTP / WebDAV / NFS), cloud services**, and connects to personal media libraries.  
It fetches beautiful metadata, artwork, and organizes everything into a clean, elegant interface.

The entire experience follows Apple’s iOS 26 design language with Liquid Glass visuals and smooth SwiftUI motion.

## Mission
- Build **Escanor Player+**, the most elegant personal media player on iOS 26.
- Deliver a calm, premium, Apple-like experience.
- Ship fast with clean, simple SwiftUI components.

## Platform & Tech
- Platform: **iOS 26**, latest SDK.
- UI: **100% SwiftUI**, minimal state, no heavy architecture.
- Playback Engine: Your custom **PlayerKit** with optional FFmpegKit for extra formats (source lives in `/Users/mohamedali/Project/PlayerKit` for reference).
- Library Sources: Local files, Files app integration, SMB, FTP, WebDAV, NFS, cloud providers.

## Core Principles
- Views stay tiny and readable — no view models or TCA.
- Prefer `@State`, `@Environment`, `@Binding`, `@Observable`.
- Keep flows async/await and simple, Apple-style.
- Prioritize clarity, calmness, and predictable UI behavior.

## Visual Language (Liquid Glass)
- Materials: system glass layers (`thin`, `ultraThin`) with depth.
- Corners: soft, large radii (20–28 pt).
- Spacing: 8pt grid (8/12/16/20/24/32).
- Typography: SF Pro / SF Arabic with consistent weight system.
- Icons: SF Symbols, thin or regular strokes.
- Colors: neutral greys + a warm gold/amber accent.
- Imagery: soft gradients, subtle shadows, no harsh contrasts.

## Motion & Haptics
- Motion: micro-transitions, 120–220ms, `.snappy` or `.easeInOut`.
- Haptics: light impact for selection, play/pause, confirmations.
- Avoid over-animation or distracting motion.

## Layout & Components
- NavigationStack + TabView (Library / Files / Network / Settings).
- **GlassCard** for movies, shows, folders, and servers.
- Library Grid: strong artwork presence, minimal chrome.
- List style: inset grouped; clean section headers.
- Player UI:
  - minimal OSD
  - scrubber with gestures
  - audio & subtitle menus
  - metadata display
- Buttons: pill-shaped, clear hierarchy.
- Sheets: translucent, soft shadow, dimmed background.

## Playback Experience
- Smooth and instant playback startup.
- Hardware-accelerated decoding via PlayerKit.
- FFmpegKit fallback for less common codecs.
- Beautiful timeline scrubbing.
- Subtitle support (embedded + external).
- Auto metadata fetching for movies & TV shows.
- Picture-in-Picture and AirPlay support.

## Accessibility & Internationalization
- RTL-friendly layout (Arabic first-class).
- Full Dynamic Type support.
- VoiceOver labels on all controls (player + library).
- Semantic colors for contrast in light/dark.

## State & Code Style
- Local state preferred; avoid global singletons.
- Observables injected only when necessary.
- Use `task`, `refreshable`, async/await.
- Helpers under `Core/` (formatting, parsing, network).
- Feature files around ~200 lines when possible.
- Use `// MARK:` for structuring code.

## Project Structure
EscanorPlayer/
App/
DesignSystem/   // GlassCard, PillButton, Materials, Colors
Player/         // Player UI, scrubber, overlays
Features/
Library/
Files/
Network/
Playlists/
Settings/
Core/           // Helpers, Local DB, File utilities
Resources/      // Assets, JSON, fonts
Packages/
PlayerKit     // Local playback engine
FFmpegKit     // Formats and codecs
## Do / Don’t
**Do**
- Use system materials, SF symbols, semantic colors.
- Keep everything responsive to text size + RTL.
- Test transitions and scrolling — must feel smooth.

**Don’t**
- Add global state or singletons.
- Over-animate or add flashy gradients.
- Introduce architecture layers (TCA, MVVM boilerplate).

## PR Checklist
- Visual style matches Liquid Glass.
- Smooth animations, no jank.
- RTL and Dynamic Type verified.
- Player controls accessible via VoiceOver.
- SwiftUI views remain simple and composable.
- No unnecessary abstractions.

## Mantra
> “A calm, glassy, cinematic player — built like Apple would build Infuse."

## Design Identity – Escanor Player

Escanor Player has a warm, cinematic visual identity built around **fire, light, and elegance**.  
The design reflects the strength of the lion, the warmth of the flame, and the calmness of Apple’s Liquid Glass aesthetic.

This section defines the core visual DNA of the app so every UI element, animation, and component feels unified.

### 1. Brand Essence
- **Warm** — glowing amber tones, soft light gradients.  
- **Premium** — clean shapes, refined shadows, high‑quality rendering.  
- **Confident** — strong contrast with a bold accent color.  
- **Cinematic** — immersive visuals with depth, lighting, and subtle motion.

The app icon (lion-shaped flame inside a black rounded glass square) sets the tone:  
luxurious, powerful, and calm at the same time.

### 2. Core Colors

#### Primary Accent — Escanor Gold
Used for highlights, selections, active states, and progress indicators.

| Purpose | Value |
|--------|--------|
| **Accent** | #FFA726 → #FF8F00 (gradient) |
| **Highlight** | #FFB74D |
| **Glow** | #FFCC80 (soft light) |

A smooth vertical or radial gradient between **#FFA726** and **#FF8F00** creates the signature Escanor glow.

#### Neutrals
Used for backgrounds, cards, lists, and typography.

| Role | Light Mode | Dark Mode |
|------|------------|-----------|
| Background | #F5F5F7 | #0A0A0A |
| Secondary BG | #FFFFFF | #1C1C1E |
| Tertiary BG | #F2F2F2 | #2C2C2E |
| Primary Text | #0A0A0A | #FFFFFF |
| Secondary Text | #5C5C5C | #A8A8A8 |

### 3. Gradients & Lighting

#### The Escanor Glow
- Warm amber tones  
- Soft blur (15–45 px)  
- Low opacity (20–35%)  

Used behind buttons, icons, thumbnails, player timeline knob.  
Avoid harsh neon or saturated orange.

#### Glass Layers
- Dark glass background (blur + 20–40% opacity)  
- No borders  
- Soft diffused shadows (8–16 px radius)  

### 4. Shape Language

#### Corners
- App-wide radii: **20, 24, 28**
- Player controls: rounded capsules
- Cards: rounded rectangles with 20–26 radius

#### Geometry
- Simple, clean shapes  
- No sharp edges  
- No decorative noise  

### 5. Typography

#### Fonts
- SF Pro Display  
- SF Arabic  

#### Weights
- Titles: Semibold  
- Body: Regular  
- Small labels: Regular or Medium  

#### Rules
- Avoid too many weight changes  
- No italics or condensed styles  
- Maintain high line height  

### 6. Iconography

#### Style
- SF Symbols  
- Regular / Thin weights  
- Consistent stroke feels  
- Prefer system shapes  

#### Colors
- Active: Escanor Gold  
- Inactive: #A8A8A8  
- Disabled: #6C6C6C  

### 7. Motion Identity

1. **Cinematic** — smooth, natural, no jumps  
2. **Soft & Minimal** — 120–220ms, `.snappy` or `.easeInOut`  
3. **Meaningful** — used for selection, transitions, or state representation  

### 8. Component Identity

#### GlassCard
- Black glass  
- Soft shadow  
- Large corners  
- Optional Escanor Glow behind artwork  

#### Pill Button
- Capsule shape  
- Escanor Gold gradient  
- Inner glow  
- White icon/text  

#### Player Timeline
- Thin glowing line  
- Knob with subtle halo  
- Light haptic when scrubbing  

#### Sheets & Popovers
- UltraThin material  
- Dimmed backdrop  
- 28 radius corners  

### 9. Personality
Escanor Player always feels:
- warm  
- premium  
- cinematic  
- minimal  
- confident  

### 10. Do / Don’t

**Do**
- Use amber gradients carefully  
- Keep UI clean  
- Use soft shadows  
- Make artwork the star  

**Don’t**
- Use neon orange  
- Add patterns or heavy textures  
- Mix inconsistent font weights  
- Over‑glow elements  
- Use bouncy animations  

---

## 11. Accent Customization (Paid Feature)

- Default accent: **Escanor Gold**
- Paid users can choose from curated accents:
  - Gold (default)
  - Amber
  - Electric Blue
  - Emerald
  - Purple
  - Red

### Accent applies to:
- Primary buttons  
- Selection states  
- Player timeline  
- Active icons  

### Brand elements always stay Gold:
- App icon  
- Logo in headers/onboarding  
- Paywall screens  

### Implementation Rules
- Use semantic colors (`Color.accentPrimary`)
- Test accent compatibility in light/dark + Dynamic Type  
- Do **not** allow custom color pickers — keep palette controlled  

---

## 12. User Preferences & Defaults Philosophy

Escanor Player uses the `Defaults` library to keep user preferences simple and maintainable.

### Principles
- All preferences defined in a single file: `UserPreferences.swift`
- Use small enums conforming to `Defaults.Serializable`
- Use `Defaults.Keys` for each stored preference
- Prefer iCloud sync for user‑facing settings
- No preference managers, coordinators, or wrappers

### Pattern Example

```swift
import Defaults
import SwiftUI

enum AccentTheme: String, CaseIterable, Defaults.Serializable, Identifiable {
    case red, teal, ocean, amber, rose, slate
    var id: Self { self }

    var displayName: String {
        switch self {
        case .red: return "Red"
        case .teal: return "Teal"
        case .ocean: return "Ocean"
        case .amber: return "Amber"
        case .rose: return "Rose"
        case .slate: return "Slate"
        }
    }

    var color: Color {
        switch self {
        case .red: return Color(hex: 0xFF3B30)
        case .teal: return Color(hex: 0x1ABC9C)
        case .ocean: return Color(hex: 0x3A8CFF)
        case .amber: return Color(hex: 0xF4A261)
        case .rose: return Color(hex: 0xF2648A)
        case .slate: return Color(hex: 0x7C8DB5)
        }
    }
}

extension Defaults.Keys {
    static let accentTheme = Key<AccentTheme>("accentTheme", iCloud: true) { .amber }
}
```

### Usage in SwiftUI

```swift
struct SettingsView: View {
    @Default(.accentTheme) private var accentTheme

    var body: some View {
        Text("Current theme: \(accentTheme.displayName)")
            .foregroundColor(accentTheme.color)
    }
}
```
