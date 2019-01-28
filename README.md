# Offender Management Allocation Client

[![Maintainability](https://api.codeclimate.com/v1/badges/00cf8469d692073171ce/maintainability)](https://codeclimate.com/github/ministryofjustice/offender-management-allocation-manager/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/00cf8469d692073171ce/test_coverage)](https://codeclimate.com/github/ministryofjustice/offender-management-allocation-manager/test_coverage) [![CircleCI](https://circleci.com/gh/ministryofjustice/offender-management-allocation-manager.svg?style=svg)](https://circleci.com/gh/ministryofjustice/offender-management-allocation-manager)

## Setup

Install the git pre-commit hook before you start working on this repository.
From the root of the repo:

```
ln -s ../../config/git-hooks/pre-commit.sh .git/hooks/pre-commit
```

### Start the application

```
$ bundle
$ rails s
```

In another terminal window, start the [Offender Management Allocation API](https://github.com/ministryofjustice/offender-management-allocation-api) on port 8000.

# Check application status
Visit `localhost:8000/status`
