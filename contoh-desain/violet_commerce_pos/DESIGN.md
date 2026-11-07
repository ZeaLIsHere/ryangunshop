---
name: Violet Commerce POS
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#4a4455'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#7b7487'
  outline-variant: '#ccc3d8'
  surface-tint: '#732ee4'
  primary: '#630ed4'
  on-primary: '#ffffff'
  primary-container: '#7c3aed'
  on-primary-container: '#ede0ff'
  inverse-primary: '#d2bbff'
  secondary: '#8127cf'
  on-secondary: '#ffffff'
  secondary-container: '#9c48ea'
  on-secondary-container: '#fffbff'
  tertiary: '#005b3d'
  on-tertiary: '#ffffff'
  tertiary-container: '#007650'
  on-tertiary-container: '#76ffc2'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#eaddff'
  primary-fixed-dim: '#d2bbff'
  on-primary-fixed: '#25005a'
  on-primary-fixed-variant: '#5a00c6'
  secondary-fixed: '#f0dbff'
  secondary-fixed-dim: '#ddb7ff'
  on-secondary-fixed: '#2c0051'
  on-secondary-fixed-variant: '#6900b3'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
  violet-deep: '#4C1D95'
  violet-vibrant: '#6D28D9'
  lavender-tint: '#EDE9FE'
  lavender-subtle: '#F5F3FF'
  surface-base: '#FAF8FE'
  surface-card: '#FFFFFF'
  text-primary: '#0F172A'
  text-muted: '#64748B'
  border-subtle: '#EDE8F5'
  status-success: '#10B981'
  status-warning: '#F59E0B'
  status-danger: '#EF4444'
typography:
  display-hero:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  display-hero-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  title-card:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  label-numeric:
    fontFamily: Plus Jakarta Sans
    fontSize: 15px
    fontWeight: '700'
    lineHeight: 20px
  label-caps:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-mobile: 0.75rem
  margin: 1.25rem
  margin-mobile: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.25rem
  space-xl: 1.5rem
---

## Brand & Style

This design system is tailored for fast-paced retail POS terminals, digital storefronts, and warung inventory management under the RyanGunshop banner. It balances brisk commercial operational speed with an elegant, modern violet aesthetic. The brand persona is authoritative, technologically forward, and composed—transforming utility-grade transactional software into a clean, premium workspace that minimizes ocular fatigue during intense retail shifts.

Drawing from soft modernism and corporate clarity, the visual style prioritizes:
- **Clean Violet Tonal Surfaces:** Layered, tinted canvas backdrops (`#FBF9FE` and `#FAF5FF`) that eliminate harsh stark-white glare while maintaining high visual hierarchy.
- **Organic Geometry:** Smooth 16px to 24px (`rounded-2xl`) corners across panels, stat widgets, and product tiles for an approachable, tactile tactile feel.
- **Deep Slate & Violet Contrast:** Crisp typography utilizing deep slate ink tones to guarantee readability in ambient store lighting and handheld glare.

## Colors

The color system delivers high legibility and operational clarity across checkout counters and inventory spreadsheets:

- **Primary (`#7C3AED` / Violet-600 & `#6D28D9` / Violet-700):** Anchors primary transactional paths, checkout confirmation triggers, primary navigation hubs, and key metrics cards.
- **Secondary (`#A855F7` / Purple-500):** Delivers subtle interactive emphasis, active tab indicators, and categorical badge borders.
- **Tertiary (`#10B981` / Emerald-500):** Represents successful payments, positive cash flow margins, and safe stock thresholds.
- **Neutrals & Surfaces:**
  - Base Screen Background: `#FAF8FE` (ultra-clean, warm violet-white).
  - Surface Elevation (Cards & Panels): `#FFFFFF`.
  - Tonal Surface Containers: Light lavender tints (`#F5F3FF` and `#EDE9FE`) providing soft, clean boundaries without heavy drop lines.
  - Deep High-Contrast Text: `#0F172A` (deep slate-900) for primary headings and currency labels, with `#64748B` (slate-500) for secondary metadata.
  - Borders: Crisp, gentle outlines at `#EDE8F5`.

## Typography

The design system uses **Plus Jakarta Sans** consistently across all digital surfaces. Its modern geometric curves complement rounded container shapes while keeping tabular figures and price tags clearly distinct.

Key typographic rules:
- **Currency & SKU Tallying:** Financial sums and transaction readouts leverage `label-numeric` and `headline-lg` with tight letter spacing for fast scanning.
- **Labeling & Status Counters:** Micro-indicators and inventory categorizations use uppercase `label-caps` with 0.04em tracking for clarity on lower-resolution POS monitors.
- **Body & Line Heights:** Kept spacious (`1.4` to `1.5` ratio) to guarantee scannability when skimming order receipts and stock replenishment tables.

## Layout & Spacing

A structured 8px layout rhythm underpins the checkout terminal and dashboard interfaces:

- **Grid Architecture:** Desktop and tablet POS displays use an 8-column or 12-column fluid grid, collapsing to a single-column or 4-column setup on handheld mobile terminals.
- **Canvas Margins:** Fixed at `1.25rem` (20px) on desktop and tablet views, tightening to `1rem` (16px) on compact handheld scanners and mobile viewports.
- **Interaction Boundaries:** All primary touch surfaces (such as add-to-cart, barcode trigger, and pay buttons) preserve a minimum height of 48px to 52px to prevent mis-taps during high-volume customer checkout queues.

## Elevation & Depth

Visual hierarchy uses clean tonal layering backed by soft, violet-tinted ambient diffusion:

- **Level 0 (Canvas):** `#FAF8FE`. Base background tone.
- **Level 1 (Dashboard Cards & Shelf Modules):** Crisp `#FFFFFF` surface accompanied by a delicate tinted ambient shadow: `box-shadow: 0px 8px 24px -4px rgba(124, 58, 237, 0.06), 0px 2px 6px -1px rgba(15, 23, 42, 0.03)`.
- **Level 2 (Active Drawers & Floating Navigation):** Lifted control panels and floating quick-checkout summaries use: `box-shadow: 0px 16px 36px -6px rgba(109, 40, 217, 0.12), 0px 4px 12px -2px rgba(15, 23, 42, 0.04)`.
- **Primary Hero Accent Panel:** Saturated violet gradient (`linear-gradient(135deg, #7C3AED 0%, #6D28D9 100%)`) with a prominent tinted glow: `box-shadow: 0px 12px 28px -6px rgba(124, 58, 237, 0.35)`.
- **Ghost Outlines:** Where separation is needed without shadow weight, a thin 1px border of `#EDE8F5` provides crisp boundaries.

## Shapes

The interface centers on modern, soft geometry with distinctive `rounded-2xl` styling:

- **Dashboard Cards & Large Containers:** Standardized at `16px` to `24px` (`rounded-2xl`) corners to soften high-density data matrices.
- **Buttons & Interactive Tags:** Configured as rounded capsules (`9999px`) or soft rectangles with `12px` to `16px` radius.
- **Icon Pods & Quick Action Badges:** Squircles radiused at `14px` inside a standard 44px to 48px square footprint.
- **Form Controls & Inputs:** Form fields and search inputs use a `12px` to `16px` corner radius to sit comfortably within parent card modules.

## Components

### Buttons & Interactive Triggers
- **Primary Action (Checkout / Bayar):** Height 50–52px, filled with Primary Violet (`#7C3AED`), active state `#6D28D9`, full pill or 16px rounded radius, bold white typography with high contrast.
- **Secondary / Ghost Action:** Lavender container background (`#F5F3FF`), border `1px solid #EDE9FE`, text color `#6D28D9`.
- **Quick Action Pods:** 48px icon containers finished in `#F5F3FF` hosting `#7C3AED` glyphs, paired with a compact 13px label beneath.

### Dashboard & POS Cards
- **Revenue & Order Summary Cards:** Pure `#FFFFFF` background, `20px` to `24px` border-radius (`rounded-2xl`), subtle border (`1px solid #EDE8F5`), soft violet shadow. Contains a top-left lavender badge, bold metrics in `#0F172A`, and positive trend pills in Emerald (`#ECFDF5`).
- **Product Item Rows & Grid Cards:** White card surface with `16px` inner radius, featuring a 56px rounded thumbnail container, product title in deep slate, SKU meta in slate-500, and a dedicated violet add-to-cart trigger.

### Chips & Status Badges
- **Active / Selected Chip:** Background `#EDE9FE`, text `#6D28D9`, border `1px solid #C4B5FD`.
- **Success / In Stock:** Soft emerald pill (`#ECFDF5`), text `#059669`.
- **Attention / Low Stock:** Soft amber pill (`#FFFBEB`), text `#D97706`.
- **Critical / Debt Alert:** Soft rose pill (`#FEF2F2`), text `#DC2626`.

### Input Fields & Search Bars
- **Search Bar:** Height 46px, `#FFFFFF` background, border `1px solid #EDE8F5`, corner radius `14px`. On focus: `border-color: #7C3AED` with a soft outer ring `rgba(124, 58, 237, 0.15)`.
- **Numeric Keypad & Calculator Buttons:** Off-white container (`#FAF8FE`) with 16px radius, bold deep slate digits, and active feedback in lavender (`#EDE9FE`).

### Floating Bottom Navigation Bar
- Positioned along the screen bottom, pure white container, `24px` top border-radius, delicate violet ambient drop shadow. Displays active navigation items highlighted with a soft lavender pill backplate and `#7C3AED` icon and text.