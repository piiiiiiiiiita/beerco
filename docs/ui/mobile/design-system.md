# BeerCo Mobile Design System

## Purpose

This design system translates the visual language from `mobile-ui-sample.html` into reusable rules for the BeerCo Flutter app.

The style is:

- operational, not decorative
- clean and modern
- soft and premium
- optimized for quick repeated use in a pub
- mobile-first with large touch targets

## Core Principles

1. Prioritize speed over novelty.
2. Keep layouts airy but information-dense.
3. Use rounded white surfaces on a very light slate background.
4. Reserve amber for emphasis, counts, and active highlights.
5. Use dark slate for primary actions and strongest text.
6. Make every state visually obvious: active, archived, paid, destructive.

## Color System

### Base

- `Background`: very light slate, around `#F8FAFC`
- `Surface`: white, `#FFFFFF`
- `Primary text`: dark slate, around `#0F172A`
- `Secondary text`: muted slate, around `#64748B`
- `Border`: soft slate border, around `#E2E8F0`

### Accent

- `Amber primary accent`: around `#F59E0B`
- `Amber soft background`: light amber tint for chips and emphasis
- `Success`: emerald/green for positive settled states
- `Danger`: warm red for delete and destructive actions

### Usage

- Use dark slate for main CTA buttons.
- Use amber for totals, counts, active highlights, and key labels.
- Use muted slate for metadata and supporting copy.
- Use green only for paid / success states.
- Use red only for destructive actions.

## Typography

- Font family: `Inter`
- Page title: `32 / 700`
- Section title: `20 / 700`
- Card title: `18 / 600`
- Primary body: `16 / 500`
- Secondary body: `14 / 500`
- Metadata / helper text: `12–13 / 500`
- Numeric emphasis: `28–32 / 700`

Rules:

- No negative letter spacing.
- Titles should feel compact and strong.
- Metadata should never compete with totals or action labels.

## Spacing

- Screen horizontal padding: `20–24`
- Vertical section gap: `24–32`
- Card internal padding: `16`
- Tight micro-gap: `4`
- Standard component gap: `8–12`
- Large gap between header and primary CTA: `20–24`

## Radius

- Primary cards: `24`
- Secondary cards / row cards: `20`
- Pills / chips / badges: `999`
- Small icon containers: `12–14`
- Bottom sheets / dialogs: `24`

## Shadows and Borders

Soft UI direction: surfaces are defined by soft diffuse shadows, not borders.

- Cards are borderless; depth comes from a soft two-layer shadow
- Avoid harsh dark shadows and hard 1px card borders
- Glass or translucent headers (detail screens) use blur + a thin bottom border only
- Inputs keep a soft filled background and subtle border for affordance

Recommended card treatment:

- white surface, no border
- soft ambient shadow: `black @5%`, blur `24`, offset `(0, 12)`
- plus a tight contact shadow: `black @3%`, blur `6`, offset `(0, 2)`

## Layout Patterns

### Screen Header

Used on all major screens.

- top aligned
- title + subtitle stack
- optional emoji or contextual label
- optional trailing actions
- should feel spacious and calm

### Primary CTA

- full width
- dark slate background
- white label
- rounded full pill shape
- minimum height `56–64`

### Section Header

- title on left
- optional count badge or utility on right

### Surface Card

- white background
- rounded corners
- borderless, soft two-layer shadow (see Shadows and Borders)
- may contain list rows, stats, or grouped controls

## Components

### 1. Primary Button

Use for:

- create table
- start session
- summary CTA when it is the strongest action

Style:

- dark background
- white text
- pill radius
- optional leading icon

### 2. Secondary / Outline Button

Use for:

- bulk actions
- less important controls

Style:

- white or tinted background
- slate border
- dark text
- rounded pill

### 3. Stat Pill

Use for:

- order counts
- active members count
- summary totals

Style:

- amber or slate tinted background
- icon optional
- compact rounded pill

### 4. Table Card

Contains:

- table identifier / name
- relative time
- order total pill
- member avatar cluster or initials
- affordance for detail

### 4b. Table Hero

The dominant card at the top of the Active Table screen.

Shape and surface:

- uneven rounded rectangle: top corners `28`, bottom corners `44`
- single base colour with a smooth top-left radial light (center around `(-0.5, -0.7)`, not fully in the corner), giving a soft inner-glow look — not an inner shadow
- soft two-layer drop shadow (borderless)

Contents:

- top-left: creator chip — mini circular avatar. Offline (no login) it shows the table-name initial; when logged in it shows the account avatar/initial and indicates who created the table
- top-right: pencil icon button (existing `AppIconCircleButton`) to rename the table
- center: stat pill with the table name (replaces a generic label)
- center: large numeric emphasis = order count, with the `objednávek` caption
- bottom: overlapping character avatars of the table members

### 5. Member Card

Contains:

- circular avatar (initial block) with a 2px white ring and soft shadow
- member name
- metadata line
- prominent order count
- quick plus / minus actions

Paid member variant:

- reduced visual prominence
- paid badge / status line
- no add action

### 6. Input Field

Style:

- pale slate filled background
- soft border
- rounded `18–20`
- large tap area

### 7. Dialog

Style:

- rounded large corners
- clear title hierarchy
- destructive action visually separated

## Motion and Interaction

- taps should feel immediate
- avoid long transitions
- swipe actions should feel native and full-height
- pressed states may slightly darken or scale

## Screen Guidance

### Home

- strong branded header
- primary CTA near top
- active tables first
- history separated into a grouped surface

### New Table

- same header language as Home
- one clear creation path
- members list uses the same surface row style as the rest of the app

### Active Table

- Table Hero at the top: creator chip, rename pencil, table-name pill, order count, member avatars
- Member quick strip under the hero: horizontal scroll, first tile is a dashed "+" (add member), each member tile (avatar + name) taps to edit name/avatar. This replaces the add-member action in the app bar.
- member list is the dominant content
- bottom menu bar (dark rounded pill): Home, +1 All, Random, Summary — tapped item expands into an icon + label pill. Only on the Active Table screen.

## Avatars

- Character avatar set (memoji-style) lives in `assets/images/avatars/`
- A member can pick an avatar (Random or a specific one) via the member options sheet; the choice is stored on the member (`avatarAsset`)
- Until a member picks one, an avatar is assigned deterministically by id so the face stays stable across sessions
- Avatars render as circles with a 2–3px white ring and a soft shadow
- Initial-letter fallback (amber-on-soft-amber) is used where no image applies (e.g. offline creator chip)

### Summary

- structured into grouped cards
- totals first, timelines after
- member event log uses compact list rows

## Do Not

- do not use gradients as the main visual identity
- do not use oversized hero marketing blocks on operational screens
- do not mix too many accent colors
- do not use hard-edged cards
- do not make destructive actions visually equal to primary actions
