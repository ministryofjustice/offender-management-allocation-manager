[![Maintainability](https://api.codeclimate.com/v1/badges/00cf8469d692073171ce/maintainability)](https://codeclimate.com/github/ministryofjustice/offender-management-allocation-manager/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/00cf8469d692073171ce/test_coverage)](https://codeclimate.com/github/ministryofjustice/offender-management-allocation-manager/test_coverage) [![CircleCI](https://circleci.com/gh/ministryofjustice/offender-management-allocation-manager.svg?style=svg)](https://circleci.com/gh/ministryofjustice/offender-management-allocation-manager)

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

- [Git-crypt](https://github.com/AGWA/git-crypt) - for securing application secrets
- [Nomis Elite2](https://github.com/ministryofjustice/elite2-api) - API for accessing prison, offender and staff information from the National Offender Management Integration System
- [Nomis Oauth2 Server](https://github.com/ministryofjustice/nomis-oauth2-server) - for logging into the application

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

## Deploying to preprod and test

preprod and test are deployed environments that can be used as part of the development process. Their purposes are:

* preprod - Contains a copy of live data, updated via a script. Only security-cleared personnel can look at it. Deploy
  here when you need to check WIP code against real data.
* test - Points to the same database as the dev/staging environment, but does not need code to be mainlined to be
  deployed to. Just like dev/staging, contains synthetic data so does not require SC to access.
  Deploy here when you need to check WIP code that requires valid NOMIS data.

The method to deploy to both branches is the same. Check any code to be deployed to a local branch, and run:

```
# Test environment
git push --force origin HEAD:test

# Preprod environment
git push --force origin HEAD:preprod
```

## Environment Variables

Several environment variables are required for the operation of this service.
Not all are required to run the service locally

Required

| Env var  | Description  |
|---|---|
| KEYWORKER_API_HOST | The host where the keyworker API is hosted |
| HMPPS_OAUTH_CLIENT_ID | The client ID of the application in OAUTH |
| NOMIS_OAUTH_HOST  |  This is the full URL of the OAUTH host where access is granted to users using the service |
| HMPPS_API_CLIENT_ID | This is the full URL of the API host where access is granted to read from the relevant APIs |
| NOMIS_OAUTH_PUBLIC_KEY  | This is the base64 encoded public key for decoding Tokens provided by the OAUTH server |
| PROMETHEUS_METRICS | If set to 'on' then will enable the generation of prometheus metrics |

Extra variables not required locally

| Env var  | Description  |
|---|---|
| DIGITAL_PRISON_SERVICE_HOST | The host where New NOMIS is hosted |
| NOMIS_OAUTH_AUTHORISATION | Oauth authorisation string (base64 encoded) |
| SENTRY_DSN | The URL of a sentry installation. If no installation is available, then this should be present but an empty string ( "" )|

## Git Hooks

Run `make setup` to install git pre-commit hooks that:

- check you have git-crypt installed
- help you avoid committing unencrypted secrets
- lint changed files using govuk rubocop

To test that the pre-commit hook is set up correctly, try removing the `diff`
attribute from a line in a `.gitattributes` file and then committing something -
the hook should prevent you from committing.

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
