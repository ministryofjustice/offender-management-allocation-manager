# AGENTS.md

## Big picture
- This is a Rails 8 app for allocating prisoners to Prison Offender Managers (POMs). The main web surface lives under `/prisons/:prison_id/...` (`config/routes.rb`); public APIs live under `/api`; admin/support tools live under `/manage`, `/sidekiq`, and `/debugging`.
- Request flow is usually: controller -> service/HMPPS API client -> local ActiveRecord model -> presenter/adapter for the view. The local DB stores allocation and handover state; prisoner/staff facts are mostly fetched live from HMPPS APIs.
- Key local records are `AllocationHistory`, `CaseInformation`, `CalculatedHandoverDate`, `PomDetail`, `Responsibility`, `EarlyAllocation`, and `LocalDeliveryUnit` (`app/models`). `OffenderService` wraps remote prison data into `MpcOffender`, and view-facing adapters like `AllocatedOffender` / `OffenderWithAllocationPresenter` merge remote offender data with local allocation state.

## Architecture and boundaries
- All prison-scoped controllers inherit from `PrisonsApplicationController`, which loads `@prison`, `@current_user`, service notifications, sorting helpers, and enforces the active caseload (`app/controllers/prisons_application_controller.rb`).
- Staff/POM prison pages often go one level deeper and inherit from `PrisonStaffApplicationController`, which centralises POM allocation filtering/sorting and handover summary helpers for screens like `CaseloadController` and `PomsController` (`app/controllers/prison_staff_application_controller.rb`, `app/controllers/caseload_controller.rb`, `app/controllers/poms_controller.rb`).
- SSO/auth is HMPPS OAuth via OmniAuth (`config/initializers/omniauth.rb`). Role checks live in `SsoIdentity` with project-specific roles: `ROLE_ALLOC_CASE_MGR` (POM), `ROLE_ALLOC_MGR` (SPO), `ROLE_MOIC_ADMIN` (admin) (`app/controllers/concerns/sso_identity.rb`).
- External integrations should usually go through `app/services/hmpps_api/*`. `HmppsApi::Client` already handles bearer auth, retries, Typhoeus, and response caching; disable cache explicitly for mutable endpoints (`app/services/hmpps_api/client.rb`).
- POM onboarding/offboarding now crosses both NOMIS user-roles and prison APIs: use `NomisUserRolesService` / `HmppsApi::NomisUserRolesApi` for staff search and role assignment/removal, but keep using `Prison#get_list_of_poms` for prison POM lists because it de-duplicates NOMIS role results and merges local `PomDetail` (`app/controllers/onboarding_controller.rb`, `app/services/nomis_user_roles_service.rb`, `app/models/prison.rb`).
- `MpcOffender` now pulls active alert labels from `HmppsApi::PrisonAlertsApi`, and Delius imports attach `LocalDeliveryUnit` rows that are synced from Mailbox Register (`app/models/mpc_offender.rb`, `app/services/hmpps_api/prison_alerts_api.rb`, `app/services/delius_data_import_service.rb`, `lib/import_local_delivery_units.rb`).
- `PrisonService.womens_prison?` is the canonical branch for women’s-estate behaviour; routes and controllers rely on it (`config/routes.rb`, `app/services/prison_service.rb`).

## Async and event flows
- ActiveJob uses Sidekiq unless `RUN_JOBS_INLINE` is set (`config/application.rb`). Queue names are in `config/sidekiq.yml` (`debounce`, `default`, `mailers`).
- Domain events are first-class here. Outbound events are built with `DomainEvents::Event` / `EventFactory` and published to SNS; inbound events are consumed from SQS by `DomainEventsConsumer` via Shoryuken (`app/lib/domain_events/*`, `app/workers/domain_events_consumer.rb`).
- Event handlers are wired centrally in `config.application.domain_event_handlers` (`config/application.rb`), not by convention scanning.
- A common cross-system flow is: inbound probation event -> `ProbationChangeHandler` -> debounced `DebouncedProcessDeliusDataJob` -> `ProcessDeliusDataJob` / `DeliusDataImportService` -> `CaseInformation` update + `AuditEvent` (`app/lib/domain_events/handlers/probation_change_handler.rb`, `app/jobs/*delius*`, `app/services/delius_data_import_service.rb`).
- Other inbound events also fan out through jobs/services rather than mutating state inline: `PrisonerUpdatedHandler` and `PrisonerReleasedHandler` enqueue prisoner status/release processing jobs, while `TierChangeHandler` updates `CaseInformation#tier` and emits an audit event (`app/lib/domain_events/handlers/*`, `app/jobs/process_prisoner_*_job.rb`).
- Another key flow is allocation/handover changes: `AllocationHistory` after-commit hooks publish audit events, outbound `allocation.changed`, and flattened PaperTrail versions; `RecalculateHandoverDateJob` may publish `handover.changed` (`app/models/allocation_history.rb`, `app/jobs/recalculate_handover_date_job.rb`).

## Project-specific conventions
- Do not put complex objects in session. Use `ApplicationController#save_to_session` so only `.attributes` hashes are stored; this matters because dev/test use cache-backed sessions to match production (`app/controllers/application_controller.rb`, `config/environments/development.rb`, `config/environments/test.rb`).
- Existing multi-step journeys often use `Wicked::Wizard` plus small `ActiveModel` form objects rather than giant AR forms. See `BuildAllocationsController` and `FemaleMissingInfosController`; `OnboardingController` is a plain controller/action flow that still uses a small `PomOnboardingForm` plus session-backed state in `app/forms/`.
- For new journeys, or when significantly refactoring an existing wizard, prefer a simpler native Rails design over adding more `Wicked::Wizard` usage. Treat Wicked as legacy/project history, not the default pattern to extend.
- Allocation and handover history rely on PaperTrail plus explicit audit rows. If you change tracked models, check both `has_paper_trail` behaviour and `AuditEvent.publish` side effects.
- Structured logs are intentional: many jobs/handlers log `event=...` key/value messages. Preserve that style when extending background flows.
- `Prison#get_list_of_poms` intentionally de-duplicates NOMIS role results and merges local `PomDetail`; use it instead of calling NOMIS directly from controllers (`app/models/prison.rb`).

## Developer workflows
- Initial setup follows `README.md`: `bundle install`, `yarn install`, `bundle exec rails db:setup`.
- Fast local web loop: `bin/dev` runs Puma + CSS watch (`Procfile.dev`, `package.json`). CSS is built by Sass into `app/assets/builds/application.css`.
- The production image in `Dockerfile` is a multi-stage Alpine build. Keep `ca-certificates` and `tzdata` in both builder and runtime: builder needs them for Bundler/Yarn plus `rails assets:precompile`, and runtime needs them for outbound HTTPS and Rails timezone data.
- Runtime also needs `libcurl` because `HmppsApi::Client` uses Faraday with the Typhoeus adapter. The image does not need the AWS CLI or legacy Bower assets; the RDS PostgreSQL trust bundle is downloaded during the build and copied to `/home/appuser/.postgresql/root.crt`.
- Background processing is separate locally: start Sidekiq with `bundle exec sidekiq -C config/sidekiq.yml` (or `./sidekiq.sh start`) and Shoryuken with `bin/rake shoryuken:start` when testing domain events.
- Local AWS/event testing uses Localstack and the SNS/SQS setup documented in `README.md`; the important env vars are `LOCALSTACK_URL`, `DOMAIN_EVENTS_TOPIC_ARN`, and `DOMAIN_EVENTS_SQS_QUEUE_NAME`.
- For Delius/LDU work, `bundle exec rake import:local_delivery_units:dry_run` previews the Mailbox Register sync and `bundle exec rake import:local_delivery_units:process` persists it (`lib/tasks/import_local_delivery_units.rake`).
- Main test command is `bundle exec rspec`. Feature specs expect Firefox + geckodriver. Tests run jobs inline, block external HTTP with WebMock, stub DPS header/footer by default, and commonly stub event publication unless metadata opts back in; check `spec/rails_helper.rb` for useful metadata hooks like `:queueing`, `:enable_allocation_change_publish`, `:skip_dps_header_footer_stubbing`, and `:skip_active_caseload_check_stubbing`.
- To match team workflow, install git hooks with `make setup`; the pre-commit hook runs GOV.UK RuboCop only on modified Ruby/Rake files (`config/git-hooks/pre-commit`).
- API docs are generated with rswag; see request/API specs under `spec/api` and browse locally at `/api-docs`.

## Documentation and writing style
- `AGENTS.md` is primarily for AI agents and other tooling, not general human-facing documentation, so keep it concise and instruction-first; apply these style rules where they help, but do not rewrite it to read like end-user docs.
- For Markdown and other documentation, keep the tone friendly, professional, and concise; prefer clear, actionable wording with minimal jargon.
- Follow GOV.UK style guidance where practical, especially for structure, clarity, grammar, and punctuation.
- Use consistent capitalisation for product names and proper nouns, for example GitHub, macOS, Docker, and Ruby.
- Use British English spelling, for example organise, behaviour, centre, travelling, and labelled.
- Write naturally, including contractions where they help the tone, but avoid sounding too casual.
