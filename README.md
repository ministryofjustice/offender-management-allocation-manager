[![Pipeline [test -> build -> deploy]](https://github.com/ministryofjustice/offender-management-allocation-manager/actions/workflows/pipeline.yml/badge.svg)](https://github.com/ministryofjustice/offender-management-allocation-manager/actions/workflows/pipeline.yml)

# Offender Management Allocation Manager

A Ruby on Rails application for allocating prisoners to Prison Offender Managers (POMs).

## Dependencies

### Versions

See `.ruby-version` file for the current Ruby version.

Use [asdf](https://asdf-vm.com/) or similar to manage your ruby environment and sets of dependencies.

### Required

- [direnv](https://direnv.net/) - for managing environment variables and storing credentials
- [Firefox](https://www.mozilla.org/en-GB/firefox/new/) - for specs
- [geckodriver](https://github.com/mozilla/geckodriver) - for specs
- [Postgres](https://www.postgresql.org) - for persisting data
- [Ruby](https://www.ruby-lang.org/) - for running app

### Optional

- [NOMIS Elite2](https://github.com/ministryofjustice/elite2-api) - API for accessing prison, offender and staff information from the National Offender Management Integration System
- [NOMIS OAuth2 Server](https://github.com/ministryofjustice/nomis-oauth2-server) - for logging into the application

### Installing Ruby

The app uses the Ruby version in `.ruby-version`.

On current macOS versions, Apple Silicon setup is usually the same as Intel: install the Xcode Command Line Tools, use an up-to-date Ruby version manager such as `asdf` or `rbenv`, and install the version from `.ruby-version`.

Install the Xcode Command Line Tools if you do not already have them:

```sh
xcode-select --install
```

Install with your Ruby version manager:

```sh
rbenv install "$(cat .ruby-version)"
```

If Ruby fails to build on Apple Silicon, install `libyaml` and `libffi` from Homebrew and retry with Homebrew's `libffi` on the compiler path:

```sh
brew install libyaml libffi
export LDFLAGS="-L/opt/homebrew/opt/libffi/lib"
export CPPFLAGS="-I/opt/homebrew/opt/libffi/include"
rbenv install "$(cat .ruby-version)"
```

## Running the application

1. If you do not already have [Bundler](https://bundler.io/), install it.

```sh
gem install bundler
```

2. Install gems locally.

```sh
bundle install
```

3. Install the frontend packages used to build the GOV.UK and MoJ styles, as defined in `package.json`.

```sh
yarn install
```

4. Create a `.env` file in the project root and add any necessary [environment variables](#environment-variables), or copy them from `.env.example`. If you need to customise the environment further, you can add a `.env.local` file that takes precedence over the default values in `.env.development`.

5. Create and seed the database.

```sh
bundle exec rails db:setup
```

6. Start the application.

```sh
bin/dev
```

This starts Puma and the CSS watcher defined in `Procfile.dev`.

7. Check the application status.

Visit [localhost:3000](http://localhost:3000)

## Running the specs

```sh
bundle exec rspec
```

## Running RuboCop

For local linting, use the wrapper script:

```sh
bin/rubocop
```

This runs RuboCop in server mode, which avoids most of the repeated startup cost on subsequent runs.

You can still run RuboCop directly through Bundler if needed:

```sh
bundle exec rubocop
```

## Localstack

If you want to test functionality that depends on AWS services locally, use Localstack to emulate them. If you are not
testing AWS-backed behaviour locally, you do not need it - the vast majority of the application works without talking to
AWS.

Install it:

    brew install localstack/tap/localstack-cli

Start it in the background:

    localstack start -d

Configure a fake local profile. Enter anything (e.g. `fake`) for the key ID and access key. Enter `eu-west-2` for
region, and `json` for output:

    aws configure --profile local

Copy the Localstack lines from `.env.example` into your `.env` file. Search for `localstack` in `.env.example`.

Create the domain events SNS topic and SQS queue and its subscription to the former:

    PAGER= AWS_PROFILE=local aws --endpoint-url=http://localhost:4566 sns create-topic --name domain-events
    PAGER= AWS_PROFILE=local aws --endpoint-url=http://localhost:4566 sqs create-queue --queue-name domain-events
    PAGER= AWS_PROFILE=local aws --endpoint-url=http://localhost:4566 sns subscribe --topic-arn arn:aws:sns:eu-west-2:000000000000:domain-events --protocol sqs --notification-endpoint arn:aws:sqs:eu-west-2:000000000000:domain-events

Start the consumer in another terminal/tab:

    bin/rake shoryuken:start

Test it in a bin/rails console:

    DomainEvents::Event.new(event_type: "noop", version: 1).publish

If no exceptions are raised, check the output of the consumer in the other terminal. If you see output, it works.

## Secrets

Secrets are stored in the `secret/allocation-manager-secrets` item in each Kubernetes namespace.

So for example, for production, one would do:

```
kubectl -n offender-management-production get secrets allocation-manager-secrets
```

These are all managed manually using `kubectl`. [See the Cloud Platform guide for more information](https://user-guide.cloud-platform.service.justice.gov.uk/documentation/other-topics/secrets.html#secrets-overview).

## Deploying to staging and preprod

Staging and preprod are deployed environments that can be used as part of the development process. Their
purposes are:

- staging - deployed on merge to `main`. It can also be deployed separately by force-pushing to the `staging` branch.
- preprod - contains a copy of live data, updated via a script. Only security-cleared personnel can access it. It is deployed on merge to `main`, just like `staging`. It cannot be deployed by force-pushing.

To deploy staging manually, commit any code to be deployed locally, and run:

```
# Staging environment
git push --force origin HEAD:staging
```

## Environment variables

Several environment variables are required for the operation of this service.
Not all are required to run the service locally.

### Required

| Env var  | Description  |
|---|---|
| KEYWORKER_API_HOST | The URL where the keyworker API is hosted |
| HMPPS_OAUTH_CLIENT_ID | The client ID of the application in OAuth |
| NOMIS_OAUTH_HOST  |  The full URL of the OAuth host where access is granted to users of the service |
| HMPPS_API_CLIENT_ID | This is the full URL of the API host where access is granted to read from the relevant APIs |
| PROMETHEUS_METRICS | If set to `on`, this enables the generation of Prometheus metrics |
| ASSESS_RISKS_AND_NEEDS_API_HOST | The URL where the Assess Risks and Needs API is hosted |

### Extra variables not required locally

| Env var  | Description  |
|---|---|
| DIGITAL_PRISON_SERVICE_HOST | The host where New NOMIS is hosted |
| NOMIS_OAUTH_AUTHORISATION | OAuth authorisation string, base64-encoded |
| SENTRY_DSN | The URL of a Sentry installation. If no installation is available, this should still be present, but as an empty string (`""`) |


## Deployment files

Helm chart files in `helm_deploy/` directory. Modify these to manage deployment.

## GitHub Actions

CI runs in GitHub Actions via `.github/workflows/pipeline.yml`.

The main pipeline currently:

- runs Helm lint checks
- runs `brakeman`
- runs `bundle exec rubocop`
- precompiles assets
- prepares the test database
- runs the RSpec suite

The RSpec step excludes specs tagged with `flaky: true` on the first run. If that first run fails, it waits briefly and
re-runs only the failed examples.

Mark specs as flaky by adding the `flaky: true` flag to them.


## Further documentation

### Domain concepts

- [Allocation, Responsibility, and Handover](docs/allocation-handover-domain.md) — explains POM/COM roles, the three responsibility states, how handover dates are calculated, and which domain events are published.

### Architectural Context

[![auto-updating container diagram](https://static.structurizr.com/workspace/56937/diagrams/manage-POM-cases-container.png)](https://structurizr.com/share/56937/diagrams#manage-POM-cases-container)

👆 edit in [hmpps-architecture-as-code](https://github.com/ministryofjustice/hmpps-architecture-as-code/blob/9990e7fbb3aa545208d2ebc40104f6f3d5a9813d/src/main/kotlin/model/manage-pom-cases.kt)

### Other

- Access the runbook in the OCM workspace of the MoJ wiki.
- [![API docs](https://img.shields.io/badge/API_docs-view-85EA2D.svg?logo=swagger)](https://allocation-manager-staging.apps.live-1.cloud-platform.service.justice.gov.uk/api-docs/index.html)
- [![Event docs](https://img.shields.io/badge/Event_docs-view-85EA2D.svg)](https://playground.asyncapi.io/?url=https://raw.githubusercontent.com/ministryofjustice/offender-management-allocation-manager/main/EarlyAllocationStatus.yml)
- [Offender Management Architecture Decisions](https://github.com/ministryofjustice/offender-management-architecture-decisions)

## Licence

[MIT Licence (MIT)](https://opensource.org/licenses/MIT)
