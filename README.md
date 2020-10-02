[![Maintainability](https://api.codeclimate.com/v1/badges/00cf8469d692073171ce/maintainability)](https://codeclimate.com/github/ministryofjustice/offender-management-allocation-manager/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/00cf8469d692073171ce/test_coverage)](https://codeclimate.com/github/ministryofjustice/offender-management-allocation-manager/test_coverage) [![CircleCI](https://circleci.com/gh/ministryofjustice/offender-management-allocation-manager.svg?style=svg)](https://circleci.com/gh/ministryofjustice/offender-management-allocation-manager)

# Offender Management Allocation Manager

A service for allocating Prisoners to Prisoner Offender Managers (POMs).

## Technical Information

This is a Ruby on Rails application that exposes an interface for Prison staff
to manage the allocation of POMs to Prisoners.

[![auto-updating container diagram](https://static.structurizr.com/workspace/56937/diagrams/omic-container.png)](https://structurizr.com/share/56937/diagrams#omic-container)

👆 edit in [hmpps-architecture-as-code](https://github.com/ministryofjustice/hmpps-architecture-as-code/blob/9990e7fbb3aa545208d2ebc40104f6f3d5a9813d/src/main/kotlin/model/OffenderManagementInCustody.kt)

### Dependencies

- [Nomis Oauth2 Server](https://github.com/ministryofjustice/nomis-oauth2-server) - for logging into the application
- [Git-crypt](https://github.com/AGWA/git-crypt) - for securing application secrets
- [Postgres](https://www.postgresql.org) - for persisting data
- [direnv](https://direnv.net/) - for managing environment variables and storing credentials
- [Nomis Elite2](https://github.com/ministryofjustice/elite2-api) - API for accessing prison, offender and staff information from the National Offender Management Integration System

### Ruby version

This application uses Ruby v2.6.3. Use [RVM](https://rvm.io/) or similar to manage your ruby environment and sets of dependencies.

### Setup

Run `make setup` to install git pre-commit hooks that:
- check you have git-crypt installed
- help you avoid committing unencrypted secrets
- lint changed files using govuk rubocop

To test that the pre-commit hook is set up correctly, try removing the `diff`
attribute from a line in a `.gitattributes` file and then committing something -
the hook should prevent you from committing.

### Running the application

1. Install Postgres

```sh
$ brew install postgres
```

2. Install gems locally

```sh
$  bundle install
```

3. Load govuk styles

```sh
yarn install
```

4. Create a .env file in the root of the folder and add any necessary [environment variables](#environment-variables) (or copy from .env.example). Load your environment variables into your current session ...

5. Create and seed database

```sh
$ rails db:setup
```

6. Start application

```sh
$ rails s
```

7. Check application status

Visit `localhost:3000/status`

### Environment variables

Several environment variables are required for the operation of this service.
Not all are required to run the service locally

Required

| Env var  | Description  |
|---|---|
| KEYWORKER_API_HOST | The host where the keyworker API is hosted |
| NOMIS_OAUTH_CLIENT_ID | The client ID of the application in OAUTH |
| NOMIS_OAUTH_HOST  |  This is the full URL of the OAUTH host where access is granted to read from the relevant APIs |
| NOMIS_OAUTH_PUBLIC_KEY  | This is the base64 encoded public key for decoding Tokens provided by the OAUTH server |
| PROMETHEUS_METRICS | If set to 'on' then will enable the generation of prometheus metrics |

Extra variables not required locally

| Env var  | Description  |
|---|---|
| DELIUS_EMAIL_USERNAME | Username for nDelius GMail import |
| DELIUS_EMAIL_PASSWORD | Password for nDelius GMail import |
| DELIUS_EMAIL_FOLDER | Folder where nDelius imports are delivered |
| DELIUS_XLSX_PASSWORD | Password for encrypted nDelius spreahsheet |
| DIGITAL_PRISON_SERVICE_HOST | The host where New NOMIS is hosted |
| NOMIS_OAUTH_AUTHORISATION | Oauth authorisation string (base64 encoded) |
| SENTRY_DSN | The URL of a sentry installation. If no installation is available, then this should be present but an empty string ( "" )|

### Further Technical Information

- Access the runbook in the OCM workspace of the MoJ wiki.
- [Offender Management Architecture Decisions](https://github.com/ministryofjustice/offender-management-architecture-decisions)

## Licence

[MIT Licence (MIT)](LICENCE)
