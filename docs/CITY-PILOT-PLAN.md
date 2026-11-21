# DARB Single-City Pilot and Expansion Plan

## Proposed launch market

**Initial operating region: Damascus city, Syria only.**

Keep the service boundary inside Damascus city governorate. Rural Damascus, other Syrian cities, and cross-city deliveries remain disabled at launch. Damascus is a single administratively defined city market and has an established network of local transport routes and commercial activity. This is a market-entry hypothesis, not a guarantee of demand or safety.

The first operational geofence inside Damascus must be a compact, contiguous service zone selected after confirming:
- real, onboarded vendors and their pickup coordinates;
- enough verified couriers and vehicle types for the expected demand;
- safe and accessible pickup/drop-off routes at operating hours;
- realistic delivery distances, fees, and customer support coverage.

Do not hard-code a neighborhood based only on assumptions. Local operations must validate the exact polygon and excluded streets before enabling customer orders. Damascus has localized access and security disruptions; movement planning and location-specific partner checks are required. See the sources below.

## Launch scope

- One city: Damascus.
- One approved geofence at a time.
- Customer, courier, vendor, and admin roles enabled only for the pilot zone.
- Store orders and independent peer-to-peer parcel delivery may be enabled only when each service has enough verified supply and operational support.
- Cash/manual settlement only if the operator has documented reconciliation and dispute procedures; do not imply online payments are available.
- Do not activate a city or delivery zone with invented stores, couriers, products, fees, or availability.

## Product and backend requirements

- Store the active city and delivery-zone status in backend configuration, not only in client-side UI.
- Validate pickup and drop-off coordinates against the active service polygon on the server.
- Reject out-of-zone orders with a clear localized explanation; never silently accept an unsupported order.
- Return only active vendors and eligible courier offers for the selected zone.
- Configure zone fees explicitly; do not use zero fees as a placeholder.
- Keep city activation behind an administrator-controlled feature flag.
- Preserve a future city model so Aleppo, Homs, Hama, and other markets can be activated later without changing the initial pilot's data.
- Keep city identifiers stable; localize display names independently of IDs.
- Record order, cancellation, acceptance, pickup, delivery, and support metrics by city and zone.

## Suggested rollout sequence

1. **Closed operations test:** admin, a small vendor cohort, and a small verified courier cohort; no public marketing.
2. **Limited customer pilot:** invite-only customers inside the geofence; cap daily orders to the support team's capacity.
3. **Zone stabilization:** fix dispatch, pickup accuracy, pricing, support, and refund/dispute workflows before increasing order volume.
4. **Expand within Damascus:** add one adjacent zone only after the current zone meets the agreed KPIs for four consecutive weeks.
5. **Second city:** choose only after Damascus operations, unit economics, courier supply, vendor onboarding, and support playbooks are repeatable.

## Proposed expansion gates

These are initial operating targets to review with the launch operator, not claims about current performance:
- at least 95% of accepted orders reach a completed or correctly resolved terminal state;
- at least 90% of completed orders arrive within the promised delivery window;
- cancellation rate below 5%, with customer, vendor, courier, and system causes tracked separately;
- median courier offer acceptance within 3 minutes during supported hours;
- crash-free mobile sessions at or above 99.5%;
- no unresolved critical security, payment, identity, or location-privacy incident;
- support coverage and vendor/courier capacity proven for the next zone.

If any critical safety, privacy, reliability, or cash-reconciliation issue is unresolved, expansion pauses regardless of order volume.

## Current backend facts to preserve

The existing project already models Syrian cities and delivery zones, and order pricing requires an explicitly configured zone. Keep those controls. Do not seed fake commercial data or activate all seeded cities merely because city records exist.

## Market and operating references

- EUAA 2026 Syria security report identifies Damascus as a distinct city governorate and lists its administrative sub-districts: https://www.ecoi.net/en/file/local/2142494/2026_07_EUAA_COI_Report_Security_Situation_Syria.pdf
- ACLED's 2026 Damascus analysis describes the capital as a comparatively more viable operating environment while emphasizing localized security and movement risks, including around particular districts and routes: https://acleddata.com/report/reengaging-damascus-syrias-capital-offers-opportunity-not-without-risk
- Oxford Business Group's 2026 Syria transport report describes transport and logistics constraints and the presence of delivery/ride-hailing services, reinforcing the need for a tightly bounded, operationally validated pilot: https://oxfordbusinessgroup.com/reports/syria/2026-report/transport/routes-reopened-infrastructure-renewal-reform-and-private-participation-are-creating-opportunities-across-key-logistics-corridors-overview/

Recheck local conditions, permissions, partner reliability, and routes immediately before launch. This plan is a product/operations recommendation, not legal or security clearance.
