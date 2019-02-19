[![Maintainability](https://api.codeclimate.com/v1/badges/00cf8469d692073171ce/maintainability)](https://codeclimate.com/github/ministryofjustice/offender-management-allocation-manager/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/00cf8469d692073171ce/test_coverage)](https://codeclimate.com/github/ministryofjustice/offender-management-allocation-manager/test_coverage) [![CircleCI](https://circleci.com/gh/ministryofjustice/offender-management-allocation-manager.svg?style=svg)](https://circleci.com/gh/ministryofjustice/offender-management-allocation-manager)

# Offender Management Allocation Manager

A service for allocating Prisoners to Prisoner Offender Managers (POMs).

## Technical Information

This is a Ruby on Rails application that exposes an interface for Prison staff
to manage the allocation of POMs to Prisoners.

### Dependencies

- [Nomis Oauth2 Server](https://github.com/ministryofjustice/nomis-oauth2-server) - for logging into the application
- [Git-crypt](https://github.com/AGWA/git-crypt) - for securing application secrets
- [Postgres](https://www.postgresql.org) - for persisting data
- [direnv](https://direnv.net/) - for managing environment variables and storing credentials
- [Nomis Elite2](https://github.com/ministryofjustice/elite2-api) - API for accessing prison, offender and staff information from the National Offender Management Integration System

### Ruby version

This application uses Ruby v2.5.3. Use [RVM](https://rvm.io/) or similar to manage your ruby environment and sets of dependencies.

### Setup

Install the git pre-commit hook before you start working on this repository so
that we're all using some checks to help us avoid committing unencrypted
secrets or unlinted code. From the root of the repo:

```
ln -s ../../config/git-hooks/pre-commit.sh .git/hooks/pre-commit
```

To test that the pre-commit hook is set up correctly, try removing the `diff`
attribute from a line in a `.gitattributes` file and then committing something -
the hook should prevent you from committing.

### Running the application

1.Install gems locally 

```sh
$ bundle install
```

2.Install the `direnv` package

```sh
$ brew install direnv
```

3.Create a .env file in the root of the folder and add any necessary environment variables. Load your environment variables into your current session ...

```sh
$ direnv allow .
```

4.Install Postgres

```sh
$ brew install postgres
```

5.Create and seed database

```sh
$ rails db:setup
```

6.Start application

```sh
$ rails s
```

7.Check application status

Visit `localhost:3000/status`

### Further Technical Information
- [Offender Management Architecture Decisions](https://github.com/ministryofjustice/offender-management-architecture-decisions)

## Licence

[MIT Licence (MIT)](LICENCE)
