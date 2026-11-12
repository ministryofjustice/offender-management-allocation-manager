# HMPPS Audit

HMPPS Audit records who accessed information or attempted an operation in this service. It is separate from local `AuditEvent` records, PaperTrail history and domain events.

For what to audit and how to choose event names and prefixes, see the [HMPPS Audit guidance](https://dsdmoj.atlassian.net/wiki/spaces/NDSS/pages/5548441708/What+should+our+service+send+to+HMPPS+Audit).

## How it works

[`HmppsAuditing`](../app/controllers/concerns/hmpps_auditing.rb), included in `ApplicationController`, wraps controller callbacks, the action and rendering. It looks up the action in [`config/hmpps_audit.yml`](../config/hmpps_audit.yml). Exempt actions and requests without a valid, unexpired SSO identity are skipped.

[`HmppsAudit::Interaction`](../app/lib/hmpps_audit/interaction.rb) publishes an `_ATTEMPT` before running the operation, then a `_SUCCESS` or `_FAILURE` afterwards. An application exception produces a failure event and is re-raised unchanged. Success describes the audited operation: successfully viewing information can count as success even when the user cannot continue a journey.

Messages follow the same HMPPS Audit contract as the [TypeScript audit client](https://github.com/ministryofjustice/hmpps-typescript-lib/blob/main/packages/audit-client/src/main/AuditClient.ts), including JSON-encoded `details`. Each [message](../app/lib/hmpps_audit/message.rb) contains:

| Field | Source |
|---|---|
| `what` | Configured event prefix plus outcome suffix |
| `who` | Signed-in username |
| `subjectType`, optional `subjectId` | Configured subject type and request parameter |
| `correlationId` | Rails request ID, shared by attempt and outcome |
| `when`, `service` | UTC publication timestamp and configured service name |
| `details` | JSON-encoded object inside the outer message |

Both events include `details.prisonId` for prison-scoped routes and any allowlisted `details.queryParams` (keys become lower camel case). Outcome details can also include displayed results, a local `entityId`, action-specific fields and a safe `failureReason`. We don't copy entire request parameters or model attributes into events.

### Delivery and diagnosis

[`HmppsAudit.publish`](../app/lib/hmpps_audit.rb) uses a shared, per-process [SQS client](../app/lib/hmpps_audit/client.rb). Sends are synchronous: the web thread waits for each send and its retries. Connection reuse, timeouts and retry limits are configured there; the shared environment opts into [AWS's updated retry behaviour](https://docs.aws.amazon.com/sdkref/latest/guide/feature-retry-behavior.html).

This matches the request-level behaviour of an awaited TypeScript audit call: its client uses `await sqsClient.send(...)`, so the calling operation also waits for SQS and retries before continuing. Node uses non-blocking I/O rather than occupying a web thread, but neither approach is background delivery. Both AWS SDKs support connection reuse and backoff retries; timeout and retry settings need not be identical.

Publishing errors are reported through `Rails.error` and swallowed so delivery failures do not fail the user's operation or replace its original exception. Unlike our wrapper, the TypeScript audit client throws by default, with options to log and suppress errors. Neither publisher provides a durable buffer or replay after SDK retries are exhausted. Audit configuration and result-collection bugs outside our publisher still raise.

An event pair isn't guaranteed: either send can fail independently, or the process can stop between them. Standard SQS can deliver duplicates or messages out of order. Use `correlationId` and event timestamps to interpret them.

Look for `event=hmpps_audit` and `event=hmpps_audit_error`, including `send_duration_ms` and `correlation_id`. Production/preprod delivery logs omit subject IDs and details. Reported errors also reach the Rails logger and Sentry when configured. Web-request exceptions carry a `request_id` tag, and audit publishing errors include `what` and `correlation_id` in the `rails.error` context.

Local mode only logs; it does not send to SQS.

### Checking events in Application Insights

In the relevant environment's Application Insights Logs, select a suitable time range and run:

```kusto
customEvents
| where cloud_RoleName == 'hmpps-audit-api'
| where customDimensions.service == "offender-management-allocation-manager"
```

Expand `customDimensions` to inspect the event. These are events logged by the downstream audit API, rather than this service's publishing logs. Allow for processing delay; if an event is missing, also check this service's delivery logs and reported errors.

The `details` payload is only visible in dev Application Insights.

## Adding an audited action

### 1. Declare the action

Use `controller_path#action` in [`config/hmpps_audit.yml`](../config/hmpps_audit.yml), including namespaces. Every routed action needs an audit declaration, an `exempt` reason, or `todo: true` while awaiting evaluation. Prefer a decision over a new `todo`.

```yaml
example_cases#show:
  what: VIEW_EXAMPLE_CASE
  subject_type: PRISONER_ID
  subject_id: prisoner_id
  query_params: [format]
```

Don't add outcome suffixes to `what`. Choose a subject type from [`Message::SUBJECT_TYPES`](../app/lib/hmpps_audit/message.rb); `subject_id` names a request parameter, not a model method. Only allowlist parameters needed to explain the operation, avoiding sensitive free text. Authentication audit belongs to HMPPS Auth.

### 2. Record displayed results and extra context

For a list, point `results` at the final collections used by the view, after filtering and pagination:

```yaml
example_cases#index:
  what: VIEW_EXAMPLE_CASES_LIST
  subject_type: NOT_APPLICABLE
  query_params: [page, sort]
  results:
    collections: [offenders]
    id: offender_no
```

This reads `@offenders` and calls `offender_no` on each item. It records unique IDs as `details.results.returnedSubjectIds` and their count as `resultCount`, on successful 2xx outcomes only. An empty list records an empty array and zero; missing collections or ID methods raise rather than silently reporting no results.

Result IDs identify the returned objects, not necessarily prisoners: staff searches return staff IDs, while audit-history lists return local `AuditEvent` IDs. The configured `results.id` determines which IDs are recorded.

Include all collections rendered across tabs, but not undisplayed pages or the full unpaginated dataset. All configured collections must support the same ID method. If the view needs custom selection, use `audit(results: ids)` instead of YAML `results`; see [`PomsController`](../app/controllers/poms_controller.rb).

Unlike YAML results, `audit(results: ids)` adds outcome details immediately, even if the request later fails or redirects. Call it only once you know those results belong to the outcome being audited.

Use `audit(details: { 'decisionUpdated' => true })` for small, action-specific outcome fields. To identify a local record, override the private `auditable_entity` method to return it; persisted ActiveRecord objects contribute `details.entityId`. See [`ResponsibilitiesController`](../app/controllers/responsibilities_controller.rb).

### 3. Check every response path

The concern classifies the final response, not whether a save was attempted:

| Response | Default audit outcome |
|---|---|
| 2xx, including implicit rendering | Success |
| Normal action redirect | Success |
| Redirect to `/401` or `/404` | Failure |
| Other redirect that halts a before-action callback | Failure |
| 401/403, 404, 422 or other non-2xx/non-redirect response | Failure, with a reason based on status |
| Application exception | Failure, then re-raise |

Validation re-renders need an explicit status, for example `render :edit, status: :unprocessable_entity`. A bare `render :edit` normally returns 200 and is therefore a success. Check implicit renders and callback responses too.

Where the status or redirect doesn't explain the outcome, call `audit(failure: ...)`. Use `HmppsAuditing::VALIDATION_FAILED` or `USER_CANCELLED` where appropriate, or a short, safe reason. Never include raw exception messages or submitted sensitive values. An explicit failure takes precedence over a successful status or redirect.

### 4. Cover the behaviour

Use the [event capture context](../spec/support/shared_contexts/hmpps_audit_event_capture.rb) and [`have_recorded_event`](../spec/support/matchers/hmpps_audit_matchers.rb) matcher in controller/feature specs. Assert the event pair, subject and relevant outcome details; check validation, denied access, cancellation and redirects where applicable. For lists, check the exact displayed IDs, pagination and empty results.

Useful references: [request behaviour specs](../spec/controllers/concerns/hmpps_auditing_spec.rb), [request ID feature spec](../spec/features/prisoner_hmpps_audit_spec.rb) and [configuration/route coverage](../spec/lib/hmpps_audit/actions_spec.rb).

Run the affected controller specs and `bundle exec rspec spec/lib/hmpps_audit/actions_spec.rb` when adding routes or declarations.
