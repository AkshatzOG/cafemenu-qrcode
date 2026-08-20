# QR Forge — Table Ordering System

Static, client-side café/restaurant ordering system: customers scan a table's
QR code, browse the menu, customize items, add to cart, and check out through
a **demo payment screen (no real gateway connected — see Known Limitations)**.
Staff manage orders, menu, and tables from `admin.html`.

## LIVE Demo -
[Admin Page/Owner's Page](https://cafemenu-qrcode.pages.dev/)

## Setup (one-time)

1. **Create a Supabase project** at supabase.com (or reuse an existing one —
   this uses its own tables, so it won't collide with unrelated projects).
2. **Run the schema.** Supabase dashboard → SQL Editor → paste the contents
   of `schema.sql` → Run.
3. **Get your API keys.** Supabase dashboard → Settings → API. Copy the
   Project URL and the `anon` `public` key.
4. **Fill in `shared/config.js`** with those two values.
5. **Create a staff login.** Supabase dashboard → Authentication → Users →
   Add user. This is the email/password used to sign into `admin.html`.
6. **Add at least one table** from the Tables tab in `admin.html` before
   testing `menu.html` — a table's QR token is what makes the menu link work.

## File structure

```
index.html          (previous standalone table-QR-only tool — optional, can delete)
menu.html            customer-facing menu, cart, checkout, live order status
admin.html            staff dashboard: orders, menu, tables/QR, branding
shared/config.js       your Supabase URL + anon key
schema.sql            run once in Supabase SQL editor
```

## Deploying

Any static host works (Cloudflare Pages, Netlify, GitHub Pages). No build
step — just push the files. Once deployed, generate table QR codes from
`admin.html` → Tables tab; they'll point at
`https://yourdomain.com/menu.html?table=<token>` automatically, based on
wherever the admin page itself is hosted.

## Known limitations (read before treating this as production-ready)

- **No real payment gateway.** Checkout is a stub — it looks like a card
  form but processes nothing. Wiring up Razorpay/Stripe is a separate,
  larger piece of work requiring business KYC.
- **Orders are readable by anyone with the anon key** (which is public by
  design in any client-side app). Postgres RLS can restrict *who* can
  write, but it can't restrict reads to "only the order you happen to
  know the ID of." Fine for a demo; not fine for a business that doesn't
  want competitors seeing order volume.
- **Single restaurant only.** One `settings` row, not a multi-tenant
  system. Turning this into "one platform, many restaurants" is a real
  redesign (tenant IDs on every table, auth scoped per-tenant), not a
  config toggle.
- **Admin CRUD is intentionally plain.** Customizations are edited as raw
  JSON in a textarea rather than a visual builder — functional over
  polished, since staff tooling matters less for a portfolio piece than
  the customer-facing flow.
