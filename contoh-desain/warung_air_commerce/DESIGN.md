---
name: Warung Air Commerce
colors:
  surface: '#faf8ff'
  surface-dim: '#d2d9f4'
  surface-bright: '#faf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f3ff'
  surface-container: '#eaedff'
  surface-container-high: '#e2e7ff'
  surface-container-highest: '#dae2fd'
  on-surface: '#131b2e'
  on-surface-variant: '#3f4850'
  inverse-surface: '#283044'
  inverse-on-surface: '#eef0ff'
  outline: '#707881'
  outline-variant: '#bfc7d2'
  surface-tint: '#006398'
  primary: '#006194'
  on-primary: '#ffffff'
  primary-container: '#007bb9'
  on-primary-container: '#fdfcff'
  inverse-primary: '#93ccff'
  secondary: '#006c49'
  on-secondary: '#ffffff'
  secondary-container: '#6cf8bb'
  on-secondary-container: '#00714d'
  tertiary: '#994100'
  on-tertiary: '#ffffff'
  tertiary-container: '#c05400'
  on-tertiary-container: '#fffbff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#cce5ff'
  primary-fixed-dim: '#93ccff'
  on-primary-fixed: '#001d31'
  on-primary-fixed-variant: '#004b73'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#ffdbca'
  tertiary-fixed-dim: '#ffb690'
  on-tertiary-fixed: '#341100'
  on-tertiary-fixed-variant: '#783200'
  background: '#faf8ff'
  on-background: '#131b2e'
  surface-variant: '#dae2fd'
typography:
  display-hero:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
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
  gutter-sm: 0.75rem
  margin: 1.25rem
  margin-mobile: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.25rem
  space-xl: 1.5rem
---

## Brand & Style

This design system targets independent micro-merchants and warung operators running high-velocity point-of-sale operations alongside spatial shelf management. It fuses tactile operational efficiency with a breezy, high-clarity minimalist aesthetic. The personality is organized, effortless, and dependable—removing visual fatigue during long retail shifts on handheld Android devices. 

Drawing heavily from modern soft-minimalist product design seen in contemporary merchant applications, the aesthetic prioritizes:
- **Clean Airflow Surfaces:** Neutral tinted backgrounds (#F8FAFC) paired with snow-white elevation cards that isolate touch clusters.
- **Friendly Geometry:** Curvature calibrated around generous 20–24px outer corners, producing approachable, comfortable containers.
- **Micro-Contrast Accents:** Soft pastel pill backgrounds embedding saturated functional glyphs (soft tangerine, emerald mint, sky blue) to enable glanceable navigation in outdoor lighting.

## Colors

The palette establishes high readability and clean categorical division across fast-moving checkout screens:

- **Primary (`#0284C7` / `#0EA5E9`):** Vibrant sky cyan that guides critical checkout flows, order submission, active navigation states, and hero revenue summary cards.
- **Secondary (`#10B981` / Emerald Mint):** Represents fulfilled states, inbound stock quantities, active cash draws, and healthy shelf inventory status. Paired with soft tint `#ECFDF5` for pill containers.
- **Tertiary (`#F97316` / Sunset Orange):** Applied to pending deliveries, quick-order actions, caution inventory levels, and transaction counts. Paired with soft background `#FFF7ED`.
- **Neutral Palette:**
  - Base Canvas: `#F8FAFC` (cool slate white preventing eye fatigue).
  - Elevated Card Surface: `#FFFFFF`.
  - Body Text / Strong Headings: `#0F172A` (deep ink slate).
  - Secondary Labels & Meta: `#64748B` (slate gray).
  - Borders & Inactive Dividers: `#E2E8F0` / `#F1F5F9`.

## Typography

The design system standardizes on **Plus Jakarta Sans** across all roles. Its geometric, open apertures and gentle curves echo the rounded card surfaces while providing crisp numeral identification—essential for price tags, stock counters, barcode SKUs, and transaction totals.

Key hierarchy principles:
- **Financial & Metrics:** Hero balances and unit numbers utilize `display-hero` and `label-numeric` with bold weights for glanceable tallying under direct sunlight.
- **Section Dividers & Shelf Clusters:** Use `headline-sm` with tight vertical spacing to conserve vertical screen estate on Android devices.
- **Navigation & Tiny Indicators:** Rendered in `label-caps` or `body-sm` using high-clarity medium weights to avoid pixel blending on low-DPI merchant hardware.

## Layout & Spacing

Layouts adhere to an 8px base rhythm arranged in an adaptive 4-column layout on phones and 8-column layout on handheld POS tablets.

- **Canvas Margins:** Set to `1.25rem` (20px) on standard viewports, dropping to `1rem` (16px) on compact handhelds.
- **Grid Gutter:** `1rem` (16px) between product tiles, statistic widgets, and category blocks.
- **Ergonomics & Touch Constraints:** All primary interactive zones (Cashier triggers, Cart add buttons, Scanner launch) enforce a minimum height and hit target of 48px to prevent miss-clicks during customer rush periods.
- **Reflow & Spatial Shelves:** For layout grid views (shelf placement and store zones), horizontal scrolling carousel strips give way to structured 2-column or 3-column modular cards.

## Elevation & Depth

Visual hierarchy relies on soft, diffused ambient light rather than heavy structural borders:

- **Level 0 (Canvas):** `#F8FAFC`. Base canvas floor.
- **Level 1 (Card & Module Surfaces):** Pure `#FFFFFF` surfaces backed by a faint, wide-spread ambient shadow: `box-shadow: 0px 8px 24px -4px rgba(15, 23, 42, 0.05), 0px 2px 6px -1px rgba(15, 23, 42, 0.02)`.
- **Level 2 (Interactive Floating Elements & Floating Nav):** Bottom bar navigation and active contextual drawers cast a deeper cushion shadow: `box-shadow: 0px 12px 32px -4px rgba(15, 23, 42, 0.08), 0px 4px 12px -2px rgba(15, 23, 42, 0.03)`.
- **Accent Surfaces (Hero Banner):** Deep sky-blue radial gradient (`linear-gradient(135deg, #0284C7 0%, #0369A1 100%)`) with a soft matching drop shadow tinted with 25% primary alpha: `0 12px 24px -6px rgba(2, 132, 199, 0.25)`.

## Shapes

The interface embraces organic, comfortable roundness:
- **Cards and Functional Modules:** Standardized to `20px` to `24px` radius (`rounded-xl`), creating floating pebble-like pods.
- **Pill Badges and Primary Buttons:** Fully radiused `9999px` (capsule format) for intuitive affordance.
- **Quick Action Icon Pods:** Soft squircle radii (`16px` to `18px`) holding centered 24px utility glyphs.
- **Input Fields & Search Bars:** Rounded at `16px` to harmonize seamlessly with surrounding modules.

## Components

### Buttons & Quick Triggers
- **Primary POS Actions:** Full capsule pill buttons, height 52px, filled with Primary `#0284C7`, text pure white 16px semibold.
- **Tile Action Pods:** 3-up cashier modules (e.g., "Active Order", "Cart", "Delivery") consist of white cards containing centered `48px x 48px` tinted square badges with `14px` squircle corners, hosting colored SVG icons, with `13px` caption labels below.

### Cards
- **Overview Stat Cards:** Crisp white background, `20px` border-radius, `space-lg` padding. Features an upper-left soft pastel rounded icon container, trailing metrics, and compact trend tags (+2.5%).
- **Product & Inventory List Cards:** Row items featuring a 56px rounded thumbnail (`12px` radius), product title, SKU code in secondary slate, and trailing right-aligned numeric stock indicator with upward/downward color-coded arrow glyphs.

### Chips & Badges
- **Status Pills:** Soft pastel container (`12%` opacity of functional tone) paired with solid text:
  - *In Stock / Increase:* Mint Green (`#ECFDF5` bg, `#059669` text).
  - *Attention / Order Queue:* Soft Peach (`#FFF7ED` bg, `#EA580C` text).
  - *Active Channel:* Pale Sky (`#F0F9FF` bg, `#0284C7` text).

### Bottom Navigation Bar
- Floats horizontally pinned to the lower screen edge, white background, `24px` top border-radius, soft top shadow. Houses five balanced slots (Home, Cashier, Scan, Inventory, Report) featuring a centered 56px floating elevated scanner ring icon in primary cyan.

### Warung Spatial Layout Grid
- Digital store shelf maps use subtle dotted guide matrices over `#F8FAFC`, with movable white modules stamped with item counters and category pastel indicators for intuitive shelf organization.