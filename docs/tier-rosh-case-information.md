# Tier, ROSH, and case information lifecycle

This note complements the existing domain docs in [`allocation-handover-domain.md`](allocation-handover-domain.md) and [`inbound-domain-events.md`](inbound-domain-events.md). It focuses on three recurring questions in the codebase:

- what tier and ROSH data mean and how they feed recommendation logic
- where the values come from, especially nDelius and the Tier API
- what happens when a case is manually created, incomplete, or not allocatable

---

## 1. Core data model

The local case record is stored in [`app/models/case_information.rb`](../app/models/case_information.rb).

Important fields:

- `tier`: one of `A`, `B`, `C`, `D`, `E`, `F`, `G`
- `rosh_level`: one of `VERY_HIGH`, `HIGH`, `MEDIUM`, `LOW`
- `manual_entry`: whether the record was created or edited manually in this service
- `enhanced_resourcing`: used to determine enhanced vs standard handover type
- `crn`, `com_name`, `com_email`, `mappa_level`, `local_delivery_unit`, etc.

The model also defines a key rule:

- `complete_for_allocation?` returns true only when both `tier` and `rosh_level` are present.

This is the practical definition of a case being “ready enough to allocate” in the normal flow.

---

## 2. How tier and ROSH drive recommendations

Recommendation logic is in [`app/services/recommendation_service.rb`](../app/services/recommendation_service.rb) and [`app/services/recommendation_service/rosh_strategy.rb`](../app/services/recommendation_service/rosh_strategy.rb).

The current strategy is simple and explicit:

- if the prisoner is an immigration case, the recommendation is a prison POM
- if the prisoner is not in a POM-responsible state (for example, a supporting-role case), the recommendation is a prison POM
- if `tier == 'A'`, the case is recommended to a probation POM
- if `rosh_level` is `VERY_HIGH` or `HIGH`, the case is recommended to a probation POM
- if `rosh_level` is blank, no recommendation is available yet
- otherwise the case is treated as a prison POM case

The important point is that the recommendation is not a separate “source of truth”; it is derived from the local `CaseInformation` values after they have been loaded or updated.

---

## 3. Where tier values come from

There are two relevant sources for tier:

### a) nDelius / probation record

When a probation record is imported, [`DeliusDataImportService`](../app/services/delius_data_import_service.rb) maps the upstream record into local `CaseInformation`.

The relevant logic is in `map_delius_to_case_info!`:

- it reads the probation record and local delivery unit
- for new records, it uses the probation tier as an initial fallback
- it sets `manual_entry: false` when the record is syncing from Delius
- it stores `com_name`, `com_email`, `crn`, `team_name`, `mappa_level`, and `rosh_level`

The tier mapping is intentionally conservative, if a record already exists and was manually edited, the service does not overwrite the current tier immediately during a Delius import. That avoids stomping on a manual value while still allowing the record to be refreshed later.

### b) authoritative Tier API

A new record may still need a more authoritative tier from the Tier API.

The code does this immediately after a new Delius record is created:

- `FetchTierJob.perform_later(case_info.crn, trigger_method:)`

This job calls `TierUpdateService.call`, which fetches `HmppsApi::TieringApi.get_tier(crn, version: 3)`, validates the returned value, and updates `CaseInformation#tier` if different.

The service then sets:

- `case_information.manual_entry = false`
- the new tier value
- audit data for the change

This is the main “authoritative tier override” path.

---

## 4. Where ROSH values come from

ROSH is populated during the same Delius import flow in [`DeliusDataImportService`](../app/services/delius_data_import_service.rb):

- if the upstream nDelius record has a ROSH value, that value wins
- if nDelius does not have a ROSH value and the current record is a manual entry, the previous manual value is kept for one import cycle
- if the record is not manual and nDelius has no ROSH value, the local value is cleared to avoid stale drift

The code comment is explicit: “Preserve manually-entered rosh for one import cycle, then let blank nDelius rosh clear it to avoid drift”.

This means ROSH is treated as a probabilistic upstream value, but with a controlled manual fallback so we do not lose a human-entered value immediately.

---

## 5. How updates arrive via events

There are two important inbound event paths.

### a) tier update events

- a `tier.calculation.changed` message arrives from the external tiering service
- the app checks whether we already have a local case record for that prisoner CRN
- if we do, it queues a background job to refresh the tier
- the background job fetches the latest tier and updates the local `CaseInformation`

This keeps the local tier aligned with the official source of truth.

### b) probation / Delius refresh events

Other inbound events, especially probation updates, are also listened for and trigger a Delius refresh. Examples in [`docs/inbound-domain-events.md`](inbound-domain-events.md):

- `probation-case.registration.added`
- `probation-case.registration.updated`
- `probation-case.registration.deleted`
- `OFFENDER_MANAGER_CHANGED`
- `OFFENDER_OFFICER_CHANGED`
- `OFFENDER_DETAILS_CHANGED`
- `probation-case.merge.completed`
- `probation-case.unmerge.completed`

These update locally stored probation-derived metadata, including:

- COM name and email
- team / LDU details
- MAPPA and ROSH-related information
- resourcing metadata

The common pattern is:

- inbound event arrives
- handler decides if this CRN is already tracked locally
- a background job debounces and refreshes the Delius-backed case information
- `DeliusDataImportService` updates `CaseInformation`

---

## 6. Manual case creation and missing information

Manual entries are used when a case cannot be fully populated from upstream data, or when a human needs to make a decision that is not available elsewhere.

The manual creation flow is in [`app/controllers/case_information_controller.rb`](../app/controllers/case_information_controller.rb):

- `create` sets `manual_entry: true`
- `update` also sets `manual_entry: true`
- the save runs with `context: :manual_entry`
- the model enforces validation specific to manual input (`tier`, `rosh_level`, `enhanced_resourcing`)

The relevant validation rules are in [`app/models/case_information.rb`](../app/models/case_information.rb):

- `rosh_level` is required on `:manual_entry`
- `enhanced_resourcing` is validated on `:manual_entry`
- `tier` is validated as one of `A` to `G`

Manual create/update is only allowed if the record is already marked as `manual_entry`. This is enforced by `ensure_editable_manual_entry`.

### Manual case behaviour

A manual case is treated as a local override. That usually means:

- if the case is later refreshed from nDelius, Delius values may overwrite or clear local values depending on the rules above
- the app keeps manual data for a bounded period when upstream data is blank, to avoid unnecessary data loss
- the case remains “manual” until a later Delius import or Tier API update resets it to a non-manual state

---

## 7. What makes a case non allocatable

The code does not use a separate `non_allocatable` field. Instead, allocatability is derived from the case information and prison-specific rules.

The key rule is in [`app/models/prison.rb`](../app/models/prison.rb):

- `offender_allocatable?(offender)` returns true only when:
  - `offender.case_information&.complete_for_allocation?` is true
  - and, for women’s prisons, `offender.complexity_level.present?` is also true

`complete_for_allocation?` is defined as:

- `tier.present? && rosh_level.present?`

So, in practical terms, a case is considered non-allocatable when either:

- tier is missing
- ROSH is missing
- the prison-specific additional requirement (for women’s prisons, complexity information) is missing

This is also why the UI has “missing information” journeys and why `CaseInformationController` blocks creating/updating a record once a case is considered complete for allocation.

---

## 8. Operational summary

The practical lifecycle is:

1. A probation record is imported from nDelius via `DeliusDataImportService`.
2. `CaseInformation` is created or updated with probation-derived values.
3. If it is a new case, a `FetchTierJob` is queued to correct the tier from the Tier API.
4. If a tier event arrives later, `TierChangeHandler` -> `ProcessTierChangeJob` -> `TierUpdateService` updates the tier in the local record.
5. If upstream ROSH or probation details change, a probation event causes a refreshed Delius import and `CaseInformation` is updated again.
6. Recommendation logic reads the current `CaseInformation` and produces the POM recommendation based on tier and ROSH.
7. A case is considered non allocatable until both values are present (and any prison-specific extra requirements are met).
