<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# UTM Parameter Convention

> **Purpose:** A cross-project standard for structuring UTM parameters on all public-facing links — email signatures, social profiles, documentation, cross-project references, and marketing materials. Ensures consistent, filterable attribution data across all analytics providers (Umami, OpenPanel, Swetrix, etc.).
>
> **Companion docs:**
> - [Analytics Playbook](./ANALYTICS_PLAYBOOK.md) — Analytics provider integrations and event tracking standards

---

## The Pattern

All outbound links to your own projects should include UTM parameters following this structure:

```
https://{project-domain}/?utm_source={project_slug}&utm_medium={channel}&utm_campaign={context}
```

### Parameter Definitions

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `utm_source` | Project slug (lowercase, no spaces) | Identifies *which project* is being linked to — useful when the same domain serves multiple purposes or when filtering in analytics |
| `utm_medium` | Channel type | Identifies *how* the visitor arrived — the distribution channel |
| `utm_campaign` | Specific context | Identifies *where specifically* in that channel the link appeared |

---

## Standard Values

### `utm_medium` (channel type)

| Value | Use When |
|-------|----------|
| `email` | Email signatures, newsletters, transactional emails |
| `social` | Social media profiles, posts, bios |
| `docs` | Documentation, README files, wikis |
| `cross-project` | Links between your own projects (e.g., project A links to project B) |
| `referral` | Partner sites, guest posts, external mentions you control |
| `qr` | QR codes on printed materials, stickers, cards |

### `utm_campaign` (specific context)

| Value | Use When |
|-------|----------|
| `signature` | Email signature links |
| `newsletter` | Newsletter links |
| `welcome-email` | Welcome/onboarding email links |
| `bio` | Social media bio/profile links |
| `post` | Social media post links (append date or ID if tracking individual posts) |
| `readme` | Project README links |
| `footer` | Website footer cross-links |
| `sidebar` | Website sidebar cross-links |
| `launch` | Launch announcements |

---

## Examples

### Email Signatures

Every project link in your email signature:

```
https://projectname.com/?utm_source=projectname&utm_medium=email&utm_campaign=signature
```

### Cross-Project Links

When Project A links to Project B (e.g., in a footer, sidebar, or "other projects" section):

```
https://projectb.com/?utm_source=projectb&utm_medium=cross-project&utm_campaign=projecta-footer
```

### Documentation Links

README or docs linking to a live demo or companion project:

```
https://projectname.com/?utm_source=projectname&utm_medium=docs&utm_campaign=readme
```

### Social Media Bio

```
https://projectname.com/?utm_source=projectname&utm_medium=social&utm_campaign=bio
```

---

## Rules

1. **Always use lowercase** for all UTM values. Analytics providers may or may not be case-sensitive — lowercase eliminates the ambiguity.
2. **Use hyphens, not underscores** for multi-word values: `welcome-email`, not `welcome_email`. (The parameter *names* use underscores per the UTM spec; the *values* use hyphens.)
3. **`utm_source` matches the project slug** — the short name you use everywhere (repo name, subdomain, etc.). Keep it consistent across all links to that project.
4. **No spaces in values.** Use hyphens instead.
5. **Don't UTM-tag internal navigation.** UTM parameters are for *inbound* attribution — links from external channels into your project. Internal links within the same site should not have UTM parameters (they overwrite the original referral source).
6. **Don't UTM-tag links to external sites you don't own.** UTM parameters are read by the *destination* site's analytics. Adding them to links to someone else's site is meaningless (unless they've asked you to).

---

## Quick Reference Template

Copy and fill in for each new link:

```
https://{domain}/?utm_source={slug}&utm_medium={channel}&utm_campaign={context}
```

| Slot | Fill With |
|------|-----------|
| `{domain}` | The project's public URL |
| `{slug}` | The project's short name (lowercase, no spaces) |
| `{channel}` | One of: `email`, `social`, `docs`, `cross-project`, `referral`, `qr` |
| `{context}` | Where specifically: `signature`, `newsletter`, `bio`, `readme`, `footer`, etc. |

---

## Audit Checklist

Use this to verify UTM consistency across your portfolio:

- [ ] All email signature links include UTM parameters
- [ ] All cross-project links include UTM parameters
- [ ] `utm_source` values are consistent per project (same slug everywhere)
- [ ] No internal navigation links have UTM parameters
- [ ] All values are lowercase with hyphens (no spaces, no underscores in values)
- [ ] Analytics dashboards show meaningful source/medium/campaign breakdowns
