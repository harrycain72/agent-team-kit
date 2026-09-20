# BL-A11Y – Accessibility and UX (WCAG 2.2 AA target)

- **BL-A11Y-1** Everything operable by keyboard, with visible focus.
- **BL-A11Y-2** Semantic HTML; labelled form controls; error messages associated with fields (`aria-describedby`, `aria-invalid`); dialogs trap and restore focus.
- **BL-A11Y-3** Status changes and errors announced through `aria-live` regions, with correct singular and plural wording.
- **BL-A11Y-4** Colour contrast at least 4.5:1; state is never conveyed by colour alone; `prefers-reduced-motion` respected.
- **BL-A11Y-5** Usable from 320 px width up; touch targets at least 44 by 44 px; no horizontal scrolling.
- **BL-A11Y-6** Every screen has loading, empty and error states. Non-field failures show a toast; field errors show at the field; input is kept on failure so the user can retry.
- **BL-A11Y-7** Light and dark mode following the system preference (Could).
- **BL-A11Y-8** Supported browsers: latest two versions of Chrome, Firefox, Safari, Edge.
- **BL-A11Y-9** Automated accessibility checks (for example axe) in component tests, plus a manual keyboard pass.
