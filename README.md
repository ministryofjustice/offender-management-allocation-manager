[![CircleCI](https://circleci.com/gh/ministryofjustice/offender-management-allocation-manager.svg?style=svg)](https://circleci.com/gh/ministryofjustice/offender-management-allocation-manager)

# Offender Management Allocation Manager

A Ruby On Rails application for allocating Prisoners to Prisoner Offender Managers (POMs).

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

- [Nomis Elite2](https://github.com/ministryofjustice/elite2-api) - API for accessing prison, offender and staff information from the National Offender Management Integration System
- [Nomis Oauth2 Server](https://github.com/ministryofjustice/nomis-oauth2-server) - for logging into the application

### Installing Ruby

The app uses Ruby 3+. Installation is a little tricky on M1 Macs:

Install libyaml: `brew install libyaml`

Use Brew's libffi, not the system's one:
`export LDFLAGS="-L/opt/homebrew/opt/libffi/lib" CPPFLAGS="-I/opt/homebrew/opt/libffi/include"`

Install with your Ruby version manager: `rbenv install 3.y.z`

## Running The Application

1. Install [Bundler](https://bundler.io/)

```sh
$ gem install bundler:2.2.28
```

2. Install gems locally

```sh
$  bundle install
```

3. Load [govuk](https://github.com/alphagov/govuk-frontend) and [MoJ](https://github.com/ministryofjustice/moj-frontend) styles (see `package.json`)

```sh
yarn install
```

4. Create a .env file in the root of the folder and add any necessary [environment variables](#environment-variables) (or copy from .env.example). Load your environment variables into your current session ...

5. Create and seed database

```sh
$ bundle exec rails db:setup
```

6. Start application

```sh
$ bundle exec rails s
```

7. Check application status

Visit [localhost:3000](http://localhost:3000)

## Running The Specs

The first time you run the specs you'll need to record the VCR cassettes:

```sh
VCR=1 bundle exec rspec
```

## Localstack

If you want to locally test functionality with AWS services, you have to use a tool called Localstack to emulate it. If
you are not testing the use of AWS locally, you do not have to do this - the vast majority of the application functions
without having to talk to AWS.

Install it:

    brew install localstack/tap/localstack-cli

Start it in the background:

    localstack start -d

Configure a fake local profile. Enter anything (e.g. `fake`) for the key ID and access key. Enter `eu-west-2` for
region, and `json` for output:

    aws configure --profile local

Copy the localstack lines from `.env.example` into your `.env` file (search for 'localstack' in .env.example)

Create the domain events SNS topic and SQS queue and its subscription to the former:

    PAGER= AWS_PROFILE=local aws --endpoint-url=http://localhost:4566 sns create-topic --name domain-events
    PAGER= AWS_PROFILE=local aws --endpoint-url=http://localhost:4566 sqs create-queue --queue-name domain-events

Start the consumer in another terminal/tab:

    bin/rake shoryuken:start

Test it in a bin/rails console:

    DomainEvents::Event.new(event_type: "noop", version: 1).publish

If no exceptions are raised, it works.

## Secrets

Secrets are stored in the `secret/allocation-manager-secrets` item in each K8s namespace.

So for example, for production, one would do:

```
kubectl -n offender-management-production get secrets allocation-manager-secrets
```

These are all managed manually using kubectl. [See here for more info](https://user-guide.cloud-platform.service.justice.gov.uk/documentation/other-topics/secrets.html#secrets-overview)

## Deploying to staging, preprod and test/test2

staging, preprod, test, and test2 are deployed environments that can be used as part of the development process. Their
purposes are:

* staging - Deployed to first before deploying to production to make sure deployment works. Can also be deployed to
  separately by force-pushing to the `staging` branch.
* preprod - Contains a copy of live data, updated via a script. Only security-cleared personnel can look at it. Deploy
  here when you need to check WIP code against real data.
* test/test2 - Points to the same database as the dev/staging environment, but does not need code to be mainlined to be
  deployed to. Just like dev/staging, contains synthetic data so does not require SC to access.
  Deploy here when you need to check WIP code that requires valid NOMIS data. However, job workers always run in staging
  so if you are testing background tasks, set the `RUN_JOBS_INLINE=1` environment variable so the jobs run when
  they are invoked.

The method to deploy to these envs is the same. Commit any code to be deployed locally, and run:

```
# Staging environment
git push --force origin HEAD:staging

# Test environment
git push --force origin HEAD:test

# Test2 environment
git push --force origin HEAD:test2

# Preprod environment
git push --force origin HEAD:preprod
```

## Environment Variables

Several environment variables are required for the operation of this service.
Not all are required to run the service locally

Required

| Env var  | Description  |
|---|---|
| KEYWORKER_API_HOST | The URL where the keyworker API is hosted |
| HMPPS_OAUTH_CLIENT_ID | The client ID of the application in OAUTH |
| NOMIS_OAUTH_HOST  |  This is the full URL of the OAUTH host where access is granted to users using the service |
| HMPPS_API_CLIENT_ID | This is the full URL of the API host where access is granted to read from the relevant APIs |
| PROMETHEUS_METRICS | If set to 'on' then will enable the generation of prometheus metrics |
| ASSESS_RISKS_AND_NEEDS_API_HOST | The URL where the Assess Risks and Needs API is hosted |

Extra variables not required locally

| Env var  | Description  |
|---|---|
| DIGITAL_PRISON_SERVICE_HOST | The host where New NOMIS is hosted |
| NOMIS_OAUTH_AUTHORISATION | Oauth authorisation string (base64 encoded) |
| SENTRY_DSN | The URL of a sentry installation. If no installation is available, then this should be present but an empty string ( "" )|

## Git Hooks

Run `make setup` to install git pre-commit hooks that:

- lint changed files using govuk rubocop

To test that the pre-commit hook is set up correctly, make an anti-rubocop change in app/models/offender.rb and
try to commit - it should stop you doing so. (If it succeeds, undo the commit).

If there are problems with Rubocop running (e.g. during a rebase session where the commits change Gemfile/Gemfile.lock)
then disable the hook first: `chmod -x .git/hooks/pre-commit`

## Deployment files

Kubernetes files in deploy/ manage deployment. Modify these to manage deployment.

### Templating System

A simple custom templating system has been built to manage these files. For now it is used to manage production cron
jobs.

Modify the relevant template in deploy/templates/, add the file to generate to the relevant job in
lib/tasks/deployment.rake, and run the rake task `bin/rake deployment:generate_jobs`.

It should not be made any more complex - if more complexity is required, stop requiring it. Simplicity is genius.

## CircleCI

CircleCI is used for testing of branches and deploying.

It runs tests in parallel and skips flaky specs.

Mark specs as flaky by adding the `flaky: true` flag to them.

To disable parallel testing in CircleCI, set the environment variable
`PARALLEL_TEST_PROCESSORS=1` in the CircleCI project settings. Delete
it from project settings to go back to the default of parallel testing.

## Further Documentation

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
