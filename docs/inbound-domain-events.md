# Inbound domain events

This document explains which upstream domain events this service consumes and, in broad terms, what business effect each one has.

It complements [`allocation-handover-domain.md`](allocation-handover-domain.md), which focuses on the domain concepts of allocation, responsibility and handover.

---

## Overview

This service consumes inbound domain events to keep local prisoner, probation and handover data in sync with upstream systems.

Most inbound events do **not** change the database directly in the queue consumer itself. Instead, they are turned into background jobs so work can be retried, sequenced and spread out.

Two patterns are used heavily:

- **Tracked-only processing** — for some event types, the service only acts when it already has a local record for that prisoner or CRN.
- **Best-effort debouncing** — where many rapid-fire updates are expected, the service waits briefly and prefers the latest event rather than processing every intermediate state.

---

## Prisoner events

### `prisoner-offender-search.prisoner.updated`

This event is used for two different purposes depending on what changed.

#### Sentence changes

If the upstream event says the prisoner's **sentence** changed, the service may queue a background handover recalculation for that prisoner.

This only happens for prisoners already tracked in `calculated_handover_dates`. It is intended to catch important sentence-driven handover changes before the next scheduled daily recalculation.

This path is debounced over a longer window so repeated sentence updates collapse into a single recalculation.

#### Status changes

If the upstream event says the prisoner's **status** changed, the service may queue near-real-time prisoner status processing.

This only happens for prisoners already tracked in `case_information`.

Status processing can lead to business effects such as:

- automatic POM deallocation when the prisoner's legal status is no longer one the service can manage
- inactivation of complexity information for a small subset of women's-prison cases
- release-style processing when the prisoner is already shown as out of prison

This path is also debounced, but over a much shorter window than sentence changes, because the service aims to react more quickly.

---

### `prisoner-offender-search.prisoner.released`

This event is used for real-time release-related processing, but only for the release reasons the service cares about immediately.

At present, the service reacts immediately to:

- `RELEASED`
- `TRANSFERRED`

Other movement reasons are not handled here in real time and are instead left to the scheduled movements processing.

In practice, this event feeds the same movement-based release logic used elsewhere in the service.

---

### `prison-offender-events.prisoner.merged`

This event is used when NOMIS merges one prisoner identity into another.

If the old prisoner identity is already represented locally, the service re-points prisoner-linked records to the canonical NOMIS ID. This keeps allocation, handover and related prisoner data attached to the surviving identity.

If the old identity is not tracked locally, the event is ignored.

---

## Probation events

### `probation-case.registration.added`
### `probation-case.registration.updated`
### `probation-case.registration.deleted`

These events refresh probation-derived case data, but only for a small subset of registration types that matter to this service.

At present, the relevant registration types are:

- `MAPP`
- `DASO`
- `INVI`

When the registration type is relevant, the service schedules a refresh of probation-derived case information for the CRN. When it is not relevant, the event is ignored.

This processing is debounced because multiple probation updates for the same CRN often arrive close together.

---

### `OFFENDER_MANAGER_CHANGED`
### `OFFENDER_OFFICER_CHANGED`
### `OFFENDER_DETAILS_CHANGED`

These events also refresh probation-derived case data for a CRN.

In practical terms, they update locally stored fields such as:

- COM name
- COM email
- team / LDU details
- MAPPA and ROSH-related information
- resourcing and related probation metadata

These updates are handled through the same debounced probation-refresh path as the registration events above.

---

### `probation-case.merge.completed`

This event is used when one probation identity is merged into another.

If the source CRN is already tracked locally, the service records the merge and re-points local probation-linked data to the canonical CRN.

If the source CRN is not tracked locally, the event is ignored.

---

### `probation-case.unmerge.completed`

This event is used when a previously merged probation identity is split back out.

If the merge relationship is already tracked locally, the service records the unmerge and restores the local case information to the reactivated CRN.

If the merge relationship is not tracked locally, the event is ignored.

---

## Tier events

### `tier.calculation.changed`

This event refreshes the stored tier on `CaseInformation`.

The service only acts when it already has a local `CaseInformation` record for the CRN. If the CRN is not tracked locally, the event is ignored.

Tier updates are processed in the background rather than inline with the queue consumer.

---

## No-op / test events

### `offender-management.noop`

This is a no-op handler used for benign event handling and logging.

---

## What inbound events can and cannot do

A few boundaries are useful to keep in mind:

- **Not every inbound event recalculates handover dates.** Sentence-related prisoner updates can do so, but most probation and tier events only refresh local supporting data.
- **Not every release-like event is handled in real time.** Some are intentionally left to the scheduled movements flow.
- **Not every upstream change matters to every prisoner.** The service often checks whether the prisoner or CRN is already tracked locally before acting.
- **Some inbound events can change allocation indirectly.** In particular, prisoner status changes can remove active POM allocations if the prisoner is no longer eligible to be managed in the normal custodial flow.

---

## Related documents

- [`allocation-handover-domain.md`](allocation-handover-domain.md) — domain overview
- [`state-charts/allocation.puml`](state-charts/allocation.puml) — allocation state transitions
