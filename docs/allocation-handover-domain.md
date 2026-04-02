# Allocation, Responsibility, and Handover

This document explains the core domain concepts around how prisoners are allocated to Prison Offender Managers (POMs), how responsibility is shared with Community Offender Managers (COMs), and how the handover process works.

---

## Key roles

| Role | Description |
|---|---|
| **POM** (Prison Offender Manager) | Prison staff. Manages the prisoner's sentence plan and risk whilst they are in custody. |
| **COM** (Community Offender Manager) | Probation staff. Manages the prisoner's community reintegration. Comes from Delius/nDelius, not NOMIS. |
| **SPO** (Senior Prison Officer) | Prison staff. Supervises POMs and manages allocation decisions for complex cases. |

---

## Allocation

An allocation is the assignment of a POM to a prisoner. In plain English: it's the answer to "which POM is responsible for this prisoner right now?"

Each prisoner has exactly one allocation record at a time. When a POM changes, the same record is updated rather than a new one created — the full history of who was assigned when is preserved automatically in the background.

For a visual overview of all possible allocation states and transitions, see the [allocation state chart](state-charts/allocation.puml) (open with any PlantUML-compatible viewer).

### POM roles on an allocation

A prisoner can have up to two POMs assigned at once:

| DB column (`allocation_history`) | Role |
|---|---|
| `primary_pom_nomis_id` | **Primary POM** — the POM who owns the case. |
| `secondary_pom_nomis_id` | **Co-working POM** — a second POM assigned alongside the primary, for shadowing, training, or complex cases. |

The primary and secondary POMs must be different people (validated at the model level).


### COM identity

The COM is **not** a NOMIS user and has no staff ID in this system. Their identity is stored in [`case_information`](../app/models/case_information.rb) as:

| DB column (`case_information`) | Content |
|---|---|
| `com_name` | Full name, synced from Delius. |
| `com_email` | Email address, synced from Delius. |

> **Why no staff ID?** POMs are NOMIS users (prison staff), so they have a NOMIS staff ID. COMs are probation staff managed in nDelius, a separate system. The two systems don't share staff identifiers, so the COM is tracked by name and email only.

---

## Responsibility

Responsibility describes **who is the lead** for a prisoner's case at any given point. It is calculated dynamically — not stored as a user-editable field — and persisted in [`calculated_handover_dates`](../app/models/calculated_handover_date.rb).

### In plain English

**POM responsible + COM supporting** — the prisoner is still in custody and not yet close to release. The POM owns the case: they lead the sentence plan, manage risk, and are the primary point of contact. The COM is involved but in a supporting role, typically preparing for the upcoming handover.

**COM responsible + POM supporting** — the prisoner is approaching release and the handover has happened. The COM now owns the case and leads community reintegration planning. The POM stays on but in a supporting role, providing context and continuity during the transition.

**Co-working POM** — entirely separate from the COM/POM responsibility split above. A co-working POM is a second POM assigned to the same prisoner alongside the primary POM — both are prison staff. It is used for shadowing, training, or complex cases needing two POMs. A co-working POM appears with the label **Co-working** on their caseload, distinct from Responsible or Supporting.

There are three possible responsibility values:

| Value (`CalculatedHandoverDate` constant) | Meaning |
|---|---|
| `CustodyOnly` | **POM responsible, no COM involvement yet.** The prisoner is in custody and their release is far enough away that handover has not started. |
| `CustodyWithCom` | **POM responsible + COM supporting.** The handover window has opened. The COM is now involved but the POM still leads. |
| `Community` | **COM responsible + POM supporting.** The handover date has passed. The COM now leads the case. |

These map to the following helper methods, which are used throughout the codebase:

```ruby
offender.pom_responsible?   # true for CustodyOnly or CustodyWithCom
offender.pom_supporting?    # true for Community
offender.com_responsible?   # true for Community
offender.com_supporting?    # true for CustodyWithCom
```

The label shown on a POM's caseload for each case is:

| Situation | Label |
|---|---|
| POM is primary POM and `pom_responsible?` | **Responsible** |
| POM is primary POM and `pom_supporting?` | **Supporting** |
| POM is the secondary/co-working POM | **Co-working** |

See [`OffenderHelper#pom_responsibility_label`](../app/helpers/offender_helper.rb) and [`AllocatedOffender`](../app/models/allocated_offender.rb).

---

## Handover

Handover is the process by which responsibility transitions from the POM to the COM as a prisoner approaches release.

### The two key dates

| Date | Meaning |
|---|---|
| **Handover start date** (`start_date`) | The COM begins supporting. Responsibility becomes `CustodyWithCom`. |
| **Handover date** (`handover_date`) | The COM takes over as responsible. Responsibility becomes `Community`. |

Both dates are stored on `calculated_handover_dates`. Responsibility is recalculated based on where today falls relative to these two dates:

```
Before start_date          → CustodyOnly       (POM responsible, no COM yet)
start_date ≤ today < handover_date → CustodyWithCom  (POM responsible + COM supporting)
today ≥ handover_date      → Community         (COM responsible + POM supporting)
```

See [`Handover::HandoverCalculation.calculate_responsibility`](../app/lib/handover/handover_calculation.rb).

### How the dates are calculated

The calculation entry point is [`HandoverDateService.handover`](../app/services/handover_date_service.rb), which delegates to [`OffenderHandover#as_calculated_handover_date`](../app/domains/offender_handover.rb).

#### OMIC policy gate

OMIC (Offender Management in Custody) is the policy framework that governs how prisoners are managed by POMs. Not every prisoner in custody falls under it — for example, under-18s, remand prisoners without a sentence, and those serving civil orders are excluded.

Handover dates are only calculated for prisoners **inside OMIC policy**, meaning they must be:
- Aged 18 or over
- Sentenced (have a release date, PED, HDCED, tariff date, or be indeterminate)
- Serving a criminal sentence (not a civil order)

> **Note on immigration cases:** immigration cases (`DET` imprisonment status) are *inside* OMIC policy — they pass this gate. However, they are then immediately assigned `Community` responsibility by the special-case rules below, so the POM is always in a supporting role for these cases.

See [`HmppsApi::Offender#inside_omic_policy?`](../app/models/hmpps_api/offender.rb).

#### Special-case rules (evaluated first, bypass date maths)

For certain types of prisoners, responsibility is fixed by policy rather than derived from release dates. These rules are checked first, and if any applies, no handover date calculation takes place. For example, a recalled prisoner always goes straight to COM responsible — the assumption is that community supervision has already begun and the COM should be leading.

Some prisoners are assigned a responsibility directly, regardless of their release dates:

| Condition | Responsibility | Reason code |
|---|---|---|
| Recalled | `Community` | `recall_case` |
| Immigration case | `Community` | `immigration_case` |
| No release date known | `CustodyOnly` | `release_date_unknown` |
| Additional ISP sentence | `CustodyOnly` | `additional_isp` |
| Indeterminate + THD ≥ 12 months away + recalled + MAPPA 0/1 | `CustodyWithCom` | `recall_thd_over_12_months` |
| Indeterminate + THD ≥ 12 months away + parole not release + MAPPA 2/3 | `Community` | `parole_mappa_2_3` |
| Indeterminate + THD ≥ 12 months away + parole not release + MAPPA 0/1 | `CustodyWithCom` | `thd_over_12_months` |

#### General date calculation rules

A few abbreviations used below:

- **THD** (Target Hearing Date) — the scheduled parole hearing date for indeterminate-sentence prisoners.
- **TED** (Tariff Expiry Date) — the minimum term an indeterminate-sentence prisoner must serve before being considered for release.
- **MAPPA** (Multi-Agency Public Protection Arrangements) — a risk-management framework. Levels 0/1 are standard cases; levels 2/3 are higher-risk cases managed by multi-agency panels.
- **ISP** (Indeterminate Sentence for Public Protection) — a now-abolished sentence type; some prisoners are still serving these.
- **Indeterminate sentence** — a sentence with no fixed end date (e.g. life imprisonment or IPP). Release is decided by a Parole Board.
- **Determinate sentence** — a sentence with a fixed length, from which a release date can be calculated.

For all other prisoners, the **handover date** is calculated as follows:

| Sentence type | Handover date |
|---|---|
| Early allocation | 15 months before earliest release date |
| Indeterminate | 12 months before earliest release date (TED or THD) |
| Determinate parole | 12 months before earliest release date |
| Standard determinate (> 10 months total) | 8 months + 14 days before earliest release date |
| Short determinate (≤ 10 months total) | `nil` → COM responsible immediately (no handover window) |

The **handover start date** equals the handover date in most cases, with one exception:

- **Indeterminate sentences in open conditions**: start date is the *earlier* of the handover date and either:
  - the date the prisoner's category changed to "open" (women's estate), or
  - the date the prisoner arrived at the open prison (men's estate).

See [`Handover::HandoverCalculation`](../app/lib/handover/handover_calculation.rb) for the full implementation.

#### Earliest release date

The handover calculation does not use all the release dates NOMIS holds — it uses a specific subset via [`MpcOffender#earliest_release_for_handover`](../app/models/mpc_offender.rb), which calls [`HandoverCalculation.calculate_earliest_release`](../app/lib/handover/handover_calculation.rb). The rules are:

- **Indeterminate sentences**: use TED if it is in the future; otherwise use THD. If neither is in the future, fall back to whichever is closest to today.
- **Determinate sentences**: use PED if present; otherwise the earliest of ARD and CRD.

### Recalculation

Responsibility is not a static label — it changes automatically over time as a prisoner gets closer to release. However, the system does not recalculate it on every page load. Instead, the dates are persisted and refreshed in the background.

Handover dates are persisted in `calculated_handover_dates` and recomputed by [`RecalculateHandoverDateJob`](../app/jobs/recalculate_handover_date_job.rb), which is triggered in three ways:

- **Nightly cron** — a scheduled Kubernetes job runs `rake recalculate_handover_dates` every weekday at 07:00, queuing the job for every active offender. This is the primary mechanism by which responsibility transitions (e.g. from `CustodyOnly` to `CustodyWithCom`) are picked up as time passes.
- **Parole review saved** — when a parole review is recorded via [`ParoleReviewsController`](../app/controllers/parole_reviews_controller.rb), the job runs immediately for that offender.
- **Early allocation saved** — when an early allocation decision is made via [`EarlyAllocationService`](../app/services/early_allocation_service.rb), the job runs immediately for that offender.

> **Note:** inbound domain events (probation changes, tier changes, prisoner status changes) do **not** directly trigger handover recalculation. `TierChangeHandler` only updates `CaseInformation#tier`; `ProbationChangeHandler` only updates `CaseInformation` fields (COM name, MAPPA level, etc.). The nightly cron picks up the downstream effect of those changes the following morning.

When the dates change, a `handover.changed` domain event is published to notify downstream systems (e.g. nDelius).

---

## Domain events

When something significant happens — a POM is allocated or a handover date changes — the system publishes a notification to other services. This allows downstream systems (for example, nDelius, the probation case management system) to react without having to poll for changes. These notifications are called domain events and are sent over a message bus (AWS SNS).

| Event type | Triggered by | Key payload fields |
|---|---|---|
| `offender-management.allocation.changed` | `AllocationHistory` after-commit, when `primary_pom_nomis_id` changes | `staffCode`, `prisonId`, `eventTrigger`, NOMS number |
| `offender-management.handover.changed` | `RecalculateHandoverDateJob`, when `start_date` or `handover_date` changes | NOMS number |

See [`DomainEvents::Event`](../app/lib/domain_events/event.rb) and [`DomainEvents::EventFactory`](../app/lib/domain_events/event_factory.rb).

### Example `allocation.changed` payload

```json
{
  "eventType": "offender-management.allocation.changed",
  "version": 1,
  "description": "A POM allocation has changed",
  "detailUrl": "https://dev.moic.service.justice.gov.uk/api/allocation/A1234BC/primary_pom",
  "occurredAt": "2026-04-02T10:30:00Z",
  "additionalInformation": {
    "staffCode": 485926,
    "prisonId": "LEI",
    "eventTrigger": "user"
  },
  "personReference": {
    "identifiers": [
      { "type": "NOMS", "value": "A1234BC" }
    ]
  }
}
```

### Example `handover.changed` payload

Unlike the allocation event, this one carries no `additionalInformation` — consumers are expected to fetch the current handover state from the `detailUrl` if they need it.

```json
{
  "eventType": "offender-management.handover.changed",
  "version": 1,
  "description": "Handover date and/or responsibility was updated",
  "detailUrl": "https://dev.moic.service.justice.gov.uk/api/handovers/A1234BC",
  "occurredAt": "2026-04-02T07:05:00Z",
  "personReference": {
    "identifiers": [
      { "type": "NOMS", "value": "A1234BC" }
    ]
  }
}
```
