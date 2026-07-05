---
name: admin-ux-audit
description: Run a structured UX audit of an admin or super-admin interface
---

<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# Cross-Project Admin UX Audit
You are conducting a structured UX audit of an admin or super-admin interface. This prompt is stack-agnostic — begin with discovery before making any recommendations or changes.
---
## PHASE 1 — DISCOVERY (read-only, no changes)
Map the project before touching anything. Answer all of the following:
### 1.1 Tech Stack
- Language(s) and runtime
- Framework (Laravel, Rails, Django, Express, Next.js, SvelteKit, WordPress, etc.)
- Template/rendering engine (Blade, ERB, Jinja, JSX, Twig, plain HTML, etc.)
- CSS approach (Tailwind, Bootstrap, custom CSS, CSS Modules, styled-components, etc.)
- JS approach (vanilla, Alpine.js, Livewire, React, Vue, HTMX, jQuery, etc.)
- Package manager and build tools
### 1.2 Rendering Model
- Server-side rendered (SSR)?
- Static generated (SSG)?
- Single-page app (SPA)?
- Hybrid (partial hydration, islands, etc.)?
- Native mobile (iOS, Android, React Native, Flutter)?
- CLI or TUI?
### 1.3 User Tiers
Identify which tiers exist in this project. Not all projects have all tiers:
| Tier | Present? | Notes |
|------|----------|-------|
| Public/guest users | | |
| Authenticated frontend users | | |
| Regular admin users | | |
| Super admin / system admin | | |
For this audit, note the **scope** — which tiers are in focus. Default: admin and super-admin.
### 1.4 Admin Surface Map
List every admin and super-admin route, view, or screen. For each, note:
- Route/URL/path
- Primary function (list, detail, form, dashboard, settings, etc.)
- Approximate data density (sparse / medium / dense)
- Estimated current mobile usability: Good / Broken / Untested
### 1.5 Existing Design Infrastructure
- Is there a design system or component library in use?
- Are there existing CSS custom properties or design tokens?
- Are there reusable UI components? Where do they live?
- What breakpoints are defined (if any)?
- Is dark mode supported?
- What's the current state of responsiveness in admin views?
### 1.6 Quick Smell Test
Before detailed analysis, flag any immediately visible issues:
- Console errors on admin pages?
- Broken layouts at 375px width?
- Missing viewport meta tag?
- Forms that submit without validation feedback?
- Empty states that show nothing?
---
## PHASE 2 — AUDIT CHECKLIST
Evaluate each admin view against the following. Score each item: ✅ Pass / ⚠️ Partial / ❌ Fail / ➖ N/A
### Navigation & Layout
```
[ ] Nav is accessible and usable on mobile (collapses, drawer, or equivalent)
[ ] No horizontal scroll at 375px, 768px, 1024px viewport widths
[ ] Page hierarchy is legible at a glance — user knows where they are
[ ] Sidebar/nav shows active/current state visually
[ ] Breadcrumbs or back navigation present for deep views
[ ] Footer / bottom nav doesn't obscure content on mobile
```
### Tables & Data Lists
```
[ ] Tables have a mobile strategy: horizontal scroll, card view, or column pruning
[ ] Long text values are truncated with full value accessible (tooltip or expand)
[ ] Tables have empty states (not a blank area or "undefined" cell)
[ ] Sortable columns are visually indicated
[ ] Row actions are usable on touch (no hover-only reveal)
[ ] Pagination or infinite scroll is implemented (no 10,000 row dumps)
[ ] Filter/search controls are accessible and functional
[ ] Active filters are visually indicated and clearable
```
### Touch & Interaction
```
[ ] All interactive elements meet 44px minimum touch target size
[ ] Tap targets have active/pressed visual feedback (not just hover states)
[ ] No functionality is exclusively behind hover interactions
[ ] Hover states have equivalent touch/click alternatives
[ ] Swipe or touch gestures do not conflict with browser navigation
[ ] Pointer-based and touch-based interactions coexist safely
    (use @media (hover: hover) to gate hover-only styles)
```
### Copy-to-Clipboard
```
[ ] IDs, slugs, tokens, API keys, URLs — all have click-to-copy
[ ] Long values are visually truncated but copy the FULL value
[ ] Copy action provides immediate visual confirmation (icon swap + toast)
[ ] On mobile, consider Web Share API as an alternative where appropriate
[ ] Code blocks and example commands have copy buttons
```
### Forms & Inputs
```
[ ] All inputs have associated <label> elements (not just placeholder text)
[ ] Input types are semantically correct: email, url, tel, number, date, etc.
[ ] Font size on inputs is 16px+ (prevents iOS auto-zoom)
[ ] Validation errors are visible, specific, and field-adjacent
[ ] Form submission has loading state (disable button + indicator)
[ ] Success confirmation is shown after submission
[ ] Destructive actions (delete, archive, disable) have confirmation steps
[ ] Required fields are marked
```
### Visual Feedback & States
```
[ ] Loading states exist for async operations (spinner, skeleton, disabled state)
[ ] Error states are handled and display useful messages (not raw stack traces)
[ ] Success states are acknowledged (toast, banner, redirect with flash message)
[ ] Empty states are designed — not blank or zero-content pages
[ ] Disabled states are visually distinct
[ ] Selected/active states are visually distinct
```
### Typography & Readability
```
[ ] Body text is 14px+ on admin views (16px preferred)
[ ] Line length is manageable on wide viewports (not full-width paragraphs)
[ ] Monospace font used for codes, tokens, IDs, technical values
[ ] Text contrast meets WCAG AA minimum (4.5:1 for body, 3:1 for large text)
[ ] Text is readable in both light and dark contexts (if applicable)
```
### Admin Convenience Features (Quality of Life)
These are not required but mark the difference between a developer tool and a good admin UI:
```
[ ] Keyboard shortcuts for frequent actions (search focus, navigate rows, etc.)
[ ] Toast/notification system for non-blocking feedback
[ ] Relative timestamps with absolute UTC tooltip on hover
[ ] Bulk actions available where applicable (select all, multi-delete, etc.)
[ ] Filter state persists across page reload (URL params or localStorage)
[ ] Clipboard access for developer-relevant values (IDs, keys, URLs)
[ ] Search/filter with debounce (not instant re-query on every keystroke)
```
---
## PHASE 3 — STACK-SPECIFIC IMPLEMENTATION RECIPES
Based on the stack identified in Phase 1, use the appropriate patterns:
### If: Tailwind CSS
```css
/* Touch target enforcement */
.btn, [role="button"], a, button {
  @apply min-h-[44px] min-w-[44px];
}
/* Hover-safe interaction states */
@media (hover: hover) {
  .copy-btn { @apply opacity-0 group-hover:opacity-100; }
}
/* Always visible on touch devices — no @media (hover: hover) wrapper */
.copy-btn { @apply opacity-100; } /* then conditionally hide on hover-capable */
/* CSS custom properties for theming */
:root {
  --color-accent: theme('colors.teal.500');
  --color-paper: theme('colors.white');
}
```
### If: Bootstrap
```html
<!-- Touch targets: use btn-lg or add padding utility -->
<!-- Use d-flex align-items-center for 44px height enforcement -->
<!-- Responsive tables: wrap in .table-responsive -->
<!-- Copy buttons: Bootstrap 5 has Clipboard.js built into docs — replicate pattern -->
```
### If: Vanilla CSS
```css
/* Touch targets */
button, a, [role="button"] {
  min-height: 44px;
  padding: 0 12px;
  display: inline-flex;
  align-items: center;
}
/* Hover-safe */
@media (hover: hover) {
  .copy-btn { opacity: 0; }
  .copy-btn:hover { opacity: 1; }
}
```
### If: React / Vue / Svelte (Component Model)
- Extract `CopyButton`, `Toast`, `TouchTarget` as reusable components
- Copy-to-clipboard: `navigator.clipboard.writeText()` with async/await
- Toast: Context/store-based notification queue
- Touch targets: Apply via a wrapper component or shared CSS class
### If: PHP + Blade (Laravel)
```blade
{{-- Copy button component --}}
@component('components.copy-button', ['value' => $apiKey])
@endcomponent
{{-- Toast system: use session flash + Alpine.js or Livewire --}}
```
### If: HTMX
- Leverage `hx-indicator` for loading states
- Use `hx-on::after-request` to trigger toast notifications
- Copy buttons: plain JS alongside HTMX (no conflict)
### If: WordPress Admin
```php
// Use admin notices for feedback
add_action('admin_notices', function() {
    echo '<div class="notice notice-success is-dismissible"><p>Done.</p></div>';
});
// Enqueue admin-specific styles/scripts
add_action('admin_enqueue_scripts', function($hook) {
    if ($hook !== 'your-page-hook') return;
    wp_enqueue_style('your-admin-style', ...);
});
```
---
## PHASE 4 — FINDINGS REPORT
Produce a structured findings document:
```markdown
# Admin UX Audit — [Project Name]
Date: [date]
Scope: [admin-only | admin+public | full]
Audited by: Claude
## Stack Summary
[Brief paragraph: language, framework, rendering, CSS approach, JS approach]
## Admin Surface Map
[List of admin routes with current state]
## Critical Issues (Fix First)
Issues that break functionality or create significant usability barriers.
### [Issue Title]
- **Where:** [route/view]
- **What:** [description]
- **Why it matters:** [impact]
- **Fix:** [specific recommendation]
- **Effort:** [low / medium / high]
## Moderate Issues
Friction points that hurt the experience but don't break it.
[same format]
## Minor / Polish
Nice-to-haves and small improvements.
[same format]
## Quick Wins (can fix in one session)
[Bulleted list of 5–10 small changes with high impact]
## Larger Efforts (plan separately)
[Bulleted list of things requiring design decisions or significant refactoring]
## Not Applicable
[Items from the checklist that don't apply to this project, with reason]
```
---
## SCOPE GUIDANCE
This audit prompt supports different scopes. The command argument determines focus:
| Scope | Focus |
|-------|-------|
| `admin-only` | Only admin and super-admin views. Public views not touched. |
| `admin+public` | Admin views deep audit. Public views: fix critical issues only, no major refactoring. |
| `full` | Complete audit of all user tiers. Public views get full treatment. |
Default if no argument: `admin-only`
---
## PROJECT TYPE MODIFIERS
Apply these additional considerations based on project type:
### Self-Hosted Developer Tools (SeeSee, POW Captcha)
- Authenticated users only — no public-facing UX concerns
- Users are technical — density > hand-holding
- Mobile: "usable in a pinch" is the bar, not primary target
- Prioritize: copy-to-clipboard, keyboard shortcuts, fast navigation
- Data is the product — optimize for scanning and finding information quickly
### Public Link/Content Apps (Booklink, CommonPrayer, Matcha)
- Two distinct UX modes: public-facing (polished) and admin (efficient)
- Public views: don't break anything, fix critical issues, no big redesigns
- Admin views: full audit — super admin needs to understand data at a glance
- Mobile: public views must be excellent; admin views should be acceptable
### Reader/Display Apps (CommonPrayer, Matcha)
- User theming/customization is a first-class feature — audit must not break it
- Super admin views are likely neglected — treat as developer-facing and improve
- Focus on: data overview, user management, content management
- Theming infrastructure used for user customization may also benefit admin views
---
## EXECUTION INSTRUCTIONS
1. Run Phase 1 completely before writing any findings. Do not skip discovery.
2. Do not make any code changes during Phase 1 or Phase 2.
3. After producing the Phase 4 report, STOP and present it for review.
4. Only begin implementing fixes after the report is reviewed and approved.
5. Implement in order: Critical → Moderate → Minor.
6. After each critical fix, verify it doesn't break any existing functionality.
7. Document all changes in CHANGELOG.md if one exists.
---
## SELF-INSTALL & AUDIT HISTORY
After completing the Phase 4 report (before any fixes), do the following automatically:
### Save this prompt to the project
Copy this prompt file into the project so it can be re-run in the future:
```
.claude/commands/admin-ux-audit.md
```
If the file already exists, do not overwrite it — it may have been customized for this project. Notify the user that it already exists.
### Save the findings report
Save the Phase 4 findings report as a dated snapshot:
```
.claude/audits/YYYY-MM-DD-admin-ux-audit.md
```
Use the current date in the filename. Never overwrite a previous audit — always create a new dated file. This builds an audit history so future runs can be compared against previous findings.
### On subsequent audit runs
If `.claude/audits/` contains a previous audit report, load the most recent one and include a **Changes Since Last Audit** section at the top of the new report:
```markdown
## Changes Since Last Audit ([previous date])
### Resolved ✅
[Issues present in the last audit that no longer appear]
### Persisting ⚠️
[Issues that were flagged before and are still present]
### New 🆕
[Issues that weren't present or weren't caught in the last audit]
```
This makes re-audits after new feature work immediately useful — you can see exactly what the new feature introduced versus what was already known.
