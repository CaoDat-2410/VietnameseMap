# Product

## Register

product

## Users

**Primary users** (role-based, all authenticated):

| Role | Context | Primary job |
|------|---------|-------------|
| Admin | Office desktop/mobile | Full system management: users, campaigns, data integrity |
| Manager | Office field | Plan campaigns, assign staff, monitor outcomes, review analytics |
| Staff | Field/mobile | Execute events, log interactions with students/schools |
| Student | Mobile | Register for campaigns, view own registration status |

Users work across desktop and mobile; field staff use phones, managers alternate between office screens and field visits. Sessions are short and task-focused — users pick up the app, complete a task, move on.

## Product Purpose

**What this product does:** Campaign management platform for school outreach in Vietnam — managers create campaigns targeting schools by province/area, staff execute events at those schools, and the platform tracks interactions and registrations.

**Why it exists:** Replace fragmented WhatsApp/email coordination with a structured system. Managers need visibility into which schools have been visited, what the outcomes were, and how many registrations came from each campaign. Staff need a mobile-friendly way to log interactions on the spot.

**What success looks like:** A manager can open the dashboard, filter by campaign or province, and immediately see: how many schools visited, interaction outcomes (interested / not interested / follow-up needed), and registration funnel. Data is accurate, latency is under 300ms, and the mobile experience doesn't feel like a degraded desktop site.

## Brand Personality

**Voice:** Professional and confident. No jargon, no filler copy. Exact labels, clear status, real data. The interface says what it means and means what it says.

**Tone:** Task-oriented. When nothing is happening, the UI is calm. When something needs attention (deadline approaching, staff overloaded), the UI signals clearly without alarm.

**Visual:** Clean, structured, data-dense where needed (tables, charts, KPIs) but never cluttered. Soft-minimalist surfaces with clear hierarchy. Indigo primary with slate neutrals — professional without being corporate-blue-generic.

**Emotional goal:** Users feel in control of their campaign pipeline. Not overwhelmed by features they don't need. Not bored by a system that talks down to them.

**In 3 words:** Structured · Visible · Capable

## Anti-references

**Generic SaaS dashboards** — The blue-everything, 12-widget grid with fake numbers, "Welcome back, John!" banners, and meaningless hero metrics. Not this.

**Government/legacy admin** — Grey forms with dense tables, no color, no hierarchy, mandatory fields that don't make sense. Not this.

**Minimalism overkill** — Blank white surfaces, invisible affordances, "just a search bar" that requires 4 clicks to do anything. Not this.

**AI-slop patterns** — Gradient text, numbered section eyebrows (01 / 02 / 03), ghost cards with 1px border + soft shadow, oversized radii, side-stripe accents, wavy SVG illustrations. Not this.

## Design Principles

1. **Data at a glance** — Every page surface shows the most critical information first. KPIs, status, counts. Detail is one tap away; not the default.

2. **Mobile-first field experience** — Staff use phones. Forms are thumb-friendly. Interactions are logged in under 30 seconds. The desktop experience enhances, not replaces.

3. **Role clarity** — Every user sees only what their role needs. Admin sees users and system. Manager sees campaigns and analytics. Staff sees their assigned events. No role ever lands on a page that shows "access denied."

4. **Graceful degradation** — Map loads progressively. Charts show empty states, not broken widgets. API failures surface as retry-able cards, not blank screens.

5. **Vietnamese first, English available** — All primary UI is in Vietnamese. Language toggle is always accessible. Date/number formats are locale-aware.

## Accessibility & Inclusion

- **WCAG 2.1 AA** target for all pages
- **Color contrast** ≥ 4.5:1 for body text, ≥ 3:1 for large text — verified per component
- **Touch targets** minimum 48px on mobile; no interactive element smaller
- **Reduced motion** respected via `prefers-reduced-motion`; no animation that gates content visibility
- **Screen reader labels** on all icon-only buttons and non-text interactive elements
- **No single-color-only indicators** — status chips use color + text label together
