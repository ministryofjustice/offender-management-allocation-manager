# Subject Access Request (SAR) developer guide

This guide covers how SAR works in the allocation manager. For guidance on
integrating with the Subject Access Request service, see the
[SAR Integration Guide](https://dsdmoj.atlassian.net/wiki/spaces/NDSS/pages/4780589084/Integration+Guide).

## How a report is built

The allocation manager supplies the data and the template. The Subject Access
Request service uses them together to render the report; this app does
not render it.

| Endpoint | What it returns |
| --- | --- |
| `GET /subject-access-request` | The report data as JSON, under the `content` key on a successful response with data. |
| `GET /subject-access-request/template` | The raw Mustache template as plain text. |

The [SAR controller](../app/controllers/api/sar_controller.rb) uses
[SubjectAccessRequestReport](../app/services/subject_access_request_report.rb)
for both endpoints. The report selector looks up the data builder in
`DATA_SERVICES` and reads the template from `config/templates/<revision>_sar_template.mustache`.
The [v1 builder](../app/services/sar_offender_data_service_v1.rb) reads local
records and uses [SAR presenters](../app/presenters/sar) to shape the JSON.
The template controls the report's labels, layout and which fields are shown.

Every field the template uses must be supported by its matching payload, with
the expected type and handling for missing values. The payload can include
extra fields that the template does not display.

## Versions and revisions

`v1-r1` means **payload format `v1`, template revision `r1`**. The revision is
selected per deployment, not by the caller: the URLs stay the same and there
is no version parameter or header.

| Change | What to do |
| --- | --- |
| Add a JSON field without displaying it | Update the existing builder or presenter, its specs, and the OpenAPI schema. No template revision is needed. |
| Change the template while keeping the payload compatible | Add a new template revision, for example `v1-r2`, and register it against the same builder. Leave the existing template untouched. |
| Make an incompatible payload change, such as renaming a field a supported template uses or changing its type | Add a new format, for example `v2-r0`, with a matching builder, template and OpenAPI schema. Keep serving the old pair where it is still configured. |

**Do not edit an approved template in place.** HAA registers a digest of the
raw template bytes and checks the template it receives against that digest.
Even whitespace, comments or markup that never renders change the digest.
Renaming the file alone does not. Arrange OSAR approval and HAA registration for
the new template before activating it in an environment.

## Making and rolling out a change

1. If the template changes, copy the existing file to the new revision's
   filename, make the edits there, and add an entry to `DATA_SERVICES`.
   Check that the selected builder supplies everything the new template uses
   and that any shared builder still supports the older registered templates.
2. Update the [payload specs](../spec/services/sar_offender_data_service_v1_spec.rb)
   and [API specs](../spec/api/sar_api_spec.rb) as needed, and cover new
   template selection in the [report selector specs](../spec/services/subject_access_request_report_spec.rb)
   and [template API specs](../spec/api/sar_template_api_spec.rb).
   Pin revisions explicitly in specs so CI covers all supported revisions,
   regardless of which one is deployed. If the payload contract changes,
   update the schema in [`spec/swagger_helper.rb`](../spec/swagger_helper.rb)
   and regenerate [`public/openapi.yml`](../public/openapi.yml).
3. Try the revision locally with `SAR_REPORT_VERSION=<revision>` and restart
   Rails. The [initializer](../config/initializers/sar_report.rb) rejects
   unregistered revisions or missing template files at startup. The selected
   value is logged at startup and on successful data requests.
4. Once OSAR approves and HAA registers the template, set `SAR_REPORT_VERSION`
   under `generic-service.env` in the relevant [Helm environment values](../helm_deploy),
   for example [`values-staging.yaml`](../helm_deploy/values-staging.yaml).
   The [shared chart values](../helm_deploy/offender-management-allocation-manager/values.yaml)
   supply the default. Verify both endpoints together before promoting the
   change. Coordinate the switch with HAA.

The [DB schema change guard](../spec/services/subject_access_request_report_spec.rb)
is a reminder to review **all supported** SAR payloads and templates after a
migration, not just the one selected in your environment.

## Retiring a revision

Once the replacement is running in every environment, HAA no longer needs
the old template, and the agreed rollback window has passed, remove the old
registry entry, template file and revision-specific specs. Remove a builder,
its specs and its OpenAPI schema only when no supported revision uses it.
Keep a link to the original template in Git history. Once a revision is
removed, switching the environment variable back is not enough to roll back:
you need the earlier release and its matching configuration.

## Revision history

Revision numbers start with the first template served by this app.

| Revision | Status | Origin |
| --- | --- | --- |
| `v1-r0` | Retired | [#2832](https://github.com/ministryofjustice/offender-management-allocation-manager/pull/2832) moved the template from the SAR HTML renderer into this service. |
| `v1-r1` | Active | [#2942](https://github.com/ministryofjustice/offender-management-allocation-manager/pull/2942) removed the calculated early allocation status section, its payload field and its database table. |

The retired template is not selectable via `SAR_REPORT_VERSION` and should not
be paired with the current payload.
