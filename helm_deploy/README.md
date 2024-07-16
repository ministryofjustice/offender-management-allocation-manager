# Deployment Notes

## Configure ENV variables in CircleCI

In order to perform deploys through CircleCI, the following ENV variables must be configured:

__Common variables__

These are added in [Project Settings > Environment Variables](https://app.circleci.com/settings/project/github/ministryofjustice/offender-management-allocation-manager/environment-variables)
and are common to any deploy environment (staging, preprod, production...)

1. `KUBE_ENV_API` with value `https://DF366E49809688A3B16EEC29707D8C09.gr7.eu-west-2.eks.amazonaws.com`
2. `KUBE_ENV_NAME` with value `DF366E49809688A3B16EEC29707D8C09.gr7.eu-west-2.eks.amazonaws.com`
3. `QUAYIO_USERNAME` (ask a team colleague if you don't have it)
4. `QUAYIO_PASSWORD` (ask a team colleague if you don't have it)

__Namespace-dependent variables__

A context needs to be created for each of the deployment envs (so one for staging, another for preprod, etc.)

1. Go to [Contexts for the Ministry of Justice's CircleCI organisation](https://app.circleci.com/settings/organization/github/ministryofjustice/contexts).
2. Click on "Create Context" button.
3. Name the context using the name of this project and the name of the environment: `offender-management-<environment>` e.g. `offender-management-staging`.
4. Click on "Add Environment Variable" button.
5. Add an environment variable called `KUBE_ENV_NAMESPACE` and set the value to the Kubernetes namespace for the environment e.g. `offender-management-staging`.
6. Using the command line, list the name of all the secrets within the Kubernetes namespace for the environment.
    ```bash
    kubectl get secrets -n <namespace>
    # E.g. kubectl get secrets -n offender-management-staging
    ```
7. Using the name of the CircleCI service account secret, retrieve the token for it.
    ```bash
    cloud-platform decode-secret -s <circleci-token-secret-name> -n <namespace> | jq -r '.data."token"'
    # E.g. cloud-platform decode-secret -s circleci-token-z123 -n offender-management-staging | jq -r '.data."token"'
    ```
8. Add an environment variable called `KUBE_ENV_TOKEN` and set the value to the response of the previous command.
9. Using the command-line, retrieve the CA certificate for the CircleCI service account.
    ```bash
    kubectl get secrets <circleci-token-secret-name> -n <namespace> -o json | jq -r '.data."ca.crt"'
    # E.g. kubectl get secrets circleci-token-z123 -n offender-management-staging -o json | jq -r '.data."ca.crt"'
    ```
10. Add an environment variable called `KUBE_ENV_CACERT` and set the value to the response of the previous command.
11. Repeat these steps for all of the environments required (preprod, production...), adding a new context for each one with their corresponding environment variables.

## Useful helm (v3) commands:

__Ensure you have Helm v3.x client installed:__

```sh
$ helm version
version.BuildInfo{Version:"v3.15.2", GitCommit:"1a500d5625419a524fdae4b33de351cc4f58ec35", GitTreeState:"clean", GoVersion:"go1.22.4"}
```

__Test chart template rendering:__

This will out the fully rendered kubernetes resources in raw yaml.

```sh
helm template [path to chart] --values=path/to/values-dev.yaml
```

__List releases:__

```sh
helm list -n [namespace]
```

__List current and previously installed application versions:__

```sh
helm history [release name] -n [namespace]
```

__Rollback to previous version:__

```sh
helm rollback [release name] [revision number] -n [namespace] --wait
```

Note: replace _revision number_ with one from listed in the `history` command)

__Example deploy command:__

The following example is `--dry-run` mode - which will allow for testing. CircleCI normally runs this command with actual secret values (from AWS secret manager), and also updates the chart's application version to match the release version:

```sh
helm upgrade [release name] [path to chart] \
  --install --wait --force --reset-values --timeout 5m --history-max 10 \
  --dry-run \
  --namespace [namespace] \
  --values path/to/values-staging.yaml
```
