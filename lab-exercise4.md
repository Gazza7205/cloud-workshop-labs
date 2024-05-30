# Lab Exercise 4

1. [Prerequisites](#1-prerequisites)
1. [Overview](#2-overview)
1. [Repository Custom Resources](#3-repository-custom-resources)
1. [Create the Repository](#4-create-the-repository)
1. [Inspect the Repository](#5-inspect-the-repository)
1. [Delete the Repository](#6-delete-the-repository)

## 1. Prerequisites

Please make sure you've completed the steps [here](./readme.md) and have completed [Lab Exercise 3](./lab-exercise3.md) before beginning this exercise.

## 2. Overview

This exercise introduces the [Repository custom resource](https://github.com/CAAPIM/layer7-operator/wiki/Repository-Custom-Resource). Repository custom resources define Git repositories (containing Graphman bundles exploded to a folder hierarchy of files) or artifact repositories (containing JSON or compressed Graphman bundle files downloadable via HTTP) that act as sources of truth for Gateway configuration as code. Repository custom resources are managed by the Layer7 Operator, and referenced by [Gateway custom resources](https://github.com/CAAPIM/layer7-operator/wiki/Gateway-Custom-Resource#repository-references) for static or dynamic configuration as code. The Layer7 Operator monitors the repositories for changes, creates local copies of the changes, and applies the changes to Gateways that reference the repositories.

[Lab Exercise 4 Recording](https://youtu.be/5m3M2QL1kp4)

## 3. Repository Custom Resources
There are several ways that Repository custom resources can be configured. This section shows two examples pointing to either a branch or tag in a Git repository.

**Branch:**

When pointing to a branch, the Layer7 Operator monitors the branch for changes, and will pull and apply the changes immediately when detected. This is fine for non-critical environments where downtime does not impact critical services.

```
apiVersion: security.brcmlabs.com/v1
kind: Repository
metadata:
  name: l7-gw-myapis
spec:
  name: l7-gw-myapis
  enabled: true
  endpoint: https://github.com/Gazza7205/l7GWMyAPIs
  branch: main
  auth:
    vendor: Github
    existingSecretName: graphman-repository-secret
    #username:
    #token:
```

**Tag:**

When pointing to a tag, the Layer7 Operator will only pull and apply changes when the Repository custom resource is created or updated (e.g. the tag value is changed). Tags effectively represent a snapshot of a Git repository at a specific point in time, and are normally part of a release cycle that includes testing. Tags facilitate idempotence and are recommended for mission critical environments.

```
apiVersion: security.brcmlabs.com/v1
kind: Repository
metadata:
  name: l7-gw-myapis
spec:
  name: l7-gw-myapis
  enabled: true
  endpoint: https://github.com/Gazza7205/l7GWMyAPIs
  #branch: main
  tag: 1.0.0
  auth:
    vendor: Github
    existingSecretName: graphman-repository-secret
    #username:
    #token:
```

## 4. Create the Repository
Let's create a basic Repository custom resource and inspect what happens.

First, if you're not still tailing the Layer7 Operator logs from the previous lab exercise, then start doing that now in a separate terminal (you may have to set your KUBECONFIG environment variable in the new terminal):

```
kubectl logs -f -l control-plane=controller-manager -c manager
```

Next, create the Repository:
<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  kubectl apply -f ./exercise4-resources/apis-repository.yaml
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  kubectl apply -f exercise4-resources\apis-repository.yaml
  ```
</details>
<br/>

## 5. Inspect the Repository
When a Repository is created the Repository Controller pulls from the provided endpoint and attempts to create a Kubernetes secret with the repository contents in Graphman bundle format (if the compressed bundle is less than 1mb).

First, inspect the Repository custom resource itself:
```
kubectl get repository l7-gw-myapis -oyaml
```

Here is an example of the previous command's output:
```
apiVersion: security.brcmlabs.com/v1
kind: Repository
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"security.brcmlabs.com/v1","kind":"Repository","metadata":{"annotations":{},"name":"l7-gw-myapis","namespace":"default"},"spec":{"auth":{"token":"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","username":"gazza7205","vendor":"Github"},"branch":"main","enabled":true,"endpoint":"https://github.com/Gazza7205/l7GWMyAPIs","name":"l7-gw-myapis"}}
  creationTimestamp: "2023-09-23T11:29:04Z"
  generation: 1
  name: l7-gw-myapis
  namespace: default
  resourceVersion: "1520888"
  uid: 2c3d927f-62ab-488f-8bf2-d281026895c6
spec:
  auth: {}
  branch: main
  enabled: true
  endpoint: https://github.com/Gazza7205/l7GWMyAPIs
  name: l7-gw-myapis
status:
  commit: 8fc74669689abe781645dac214ebf26eb7480c78
  name: l7-gw-myapis
  ready: true
  storageSecretName: l7-gw-myapis-repository-main
  updated: 2023-09-23 11:29:04.79779696 +0000 UTC m=+397892.187935088
  vendor: Github
```

Then, inspect the storage secret created by the Repository Controller:
<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  kubectl get secret l7-gw-myapis-repository-main -ojsonpath="{.data['l7-gw-myapis\.gz']}" | base64 -d | gzip -d
  ```
  Here is an example of the previous command's output:
  ```
  {
    "webApiServices": [
      {
        "goid": "84449671abe2a5b143051dbdfdf7e685",
        "folderPath": "/myApis",
        "name": "Rest Api 1",
        "resolutionPath": "/api1",
        "policy": {
          "xml": "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<wsp:Policy xmlns:L7p=\"http://www.layer7tech.com/ws/policy\" xmlns:wsp=\"http://schemas.xmlsoap.org/ws/2002/12/policy\">\n    <wsp:All wsp:Usage=\"Required\">\n        <L7p:SetVariable>\n            <L7p:Base64Expression stringValue=\"aGVsbG8gYXBpIDE=\"/>\n            <L7p:VariableToSet stringValue=\"service_specific_var\"/>\n        </L7p:SetVariable>\n        <L7p:Include>\n            <L7p:PolicyGuid stringValue=\"a9f7163b-d17a-42e8-9b75-855ca6f67c08\"/>\n        </L7p:Include>\n    </wsp:All>\n</wsp:Policy>\n"
        },
        "enabled": true,
        "methodsAllowed": [
          "GET",
          "POST",
          "PUT"
        ],
        "tracingEnabled": false,
        "wssProcessingEnabled": false,
        "checksum": "ad069ae7b081636f7334ff76b99d09b75dd79b81"
      },
      {
        "goid": "84449671abe2a5b143051dbdfdf7e716",
        "folderPath": "/myApis",
        "name": "Rest Api 2",
        "resolutionPath": "/api2",
        "policy": {
          "xml": "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<wsp:Policy xmlns:L7p=\"http://www.layer7tech.com/ws/policy\" xmlns:wsp=\"http://schemas.xmlsoap.org/ws/2002/12/policy\">\n    <wsp:All wsp:Usage=\"Required\">\n        <L7p:SetVariable>\n            <L7p:Base64Expression stringValue=\"aGVsbG8gYXBpIDI=\"/>\n            <L7p:VariableToSet stringValue=\"service_specific_var\"/>\n        </L7p:SetVariable>\n        <L7p:Include>\n            <L7p:PolicyGuid stringValue=\"a9f7163b-d17a-42e8-9b75-855ca6f67c08\"/>\n        </L7p:Include>\n    </wsp:All>\n</wsp:Policy>\n"
        },
        "enabled": true,
        "methodsAllowed": [
          "GET",
          "POST",
          "PUT",
          "DELETE"
        ],
        "tracingEnabled": false,
        "wssProcessingEnabled": false,
        "checksum": "6b2e555519d62f84fac207a1b846a2d2d83955cc"
      },
      {
        "goid": "982cc1ee7369c6ca5a7ae1e4ad8ba399",
        "folderPath": "/myApis",
        "name": "test headers",
        "resolutionPath": "/testheaders",
        "policy": {
          "xml": "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<wsp:Policy xmlns:L7p=\"http://www.layer7tech.com/ws/policy\" xmlns:wsp=\"http://schemas.xmlsoap.org/ws/2002/12/policy\">\n    <wsp:All wsp:Usage=\"Required\">\n        <L7p:HardcodedResponse>\n            <L7p:Base64ResponseBody stringValue=\"aGVhZGVycwoke3JlcXVlc3QuaHR0cC5hbGxoZWFkZXJ2YWx1ZXN9\"/>\n            <L7p:ResponseContentType stringValue=\"text/plain; charset=UTF-8\"/>\n        </L7p:HardcodedResponse>\n    </wsp:All>\n</wsp:Policy>\n"
        },
        "enabled": true,
        "methodsAllowed": [
          "GET",
          "POST",
          "PUT",
          "DELETE"
        ],
        "tracingEnabled": false,
        "wssProcessingEnabled": false,
        "checksum": "e272c84aa976bdd0d4973344b03123005ff473dd"
      }
    ]
  }
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  kubectl get secret l7-gw-myapis-repository-main -ojsonpath="{.data['l7-gw-myapis\.gz']}"
  ```
  Here is an example of the previous command's output (base64 encoded gzipped file; to see decoded and unzipped file contents check out the Linux/MacOS example above):
  ```
  H4sIAAAAAAAA/+yVb0/jRhDGv4o1r534v9d2FZ3CXS7HCbUUQo7jfDqtd8exxdrretc4EeK7VyakAY4CL6qqlXi1UmaeeXZ25hdfQ4/ZtClPsb0qGSpIvl3DSpYcEoh8349D4tAMXRpkju/ZgcMznvOcYBgFYEIuBcf2mOoCErCqzbQpFZhQ0wohgRNU2pg2peGACS0qKTpdynqXTptyCDRSlGwDyTWsKwEJpJ1te+zduhLGFbaqlPUkBWdsp2BgzSQv69UkhbPFx1GUwrvbbEzrrapXTXJ8W89YV6JWyRFpJikUWjeJZfV9PxZ0gy3RyIoxk5XVK2vrn8Kdolf3FIoVWFE1XldCSdqMZbsaJK5tu5bj/iXdXcIwDGN/kakQxnCeKbrCSQon+EdXtsgf5u81R6RJTlEvaVvSTODjpIeJB1Rh6M/WTYtqeCND6basV0squsGLzpcqm0err+cHzeGH2SQF6/l6O9eFPEX9qJjaLscP1SAr85L9uKLtEwW3xawX2thbHtZMdPyFPrfTnHclf9xhnBMn9LIRdwgd+S5GozgjwSgKAkbDPCTMjp6/5BP+d9G76T3cLWu/XLsA3JiA9dAlh0S3HZpQoS4kV1MhZD/8+g3mswWYcPzb6e1xtoDvJuiWsrJezXbanAqFJvRKHbeSDRP9OcgKZJeqqyAByu0wpkgyO3JCL8yJ5/l5TsIsjrk9vALnJM4iB27M19FMnPD1NLt/R7P7RvO/QfPhG83/IZpN+DA7mi1m/wDWYeZiEASBE/PQzSM/p8y1CXWyyA+py10eeXEQMHYf6zhyGXMQiRfGLGQ0oISigz7lUUa9OH4Raz1gXSDl2KonwR4S9vE3vu+t8yfaciY58hNUjazVqyjf5R5IvvmZ8+JivtywXl6i91mw86Vg3u8d/XRis/dBkc3X8uLLx8uL88/u1y9r5+L81/jF/4Kd33tZa6z1YtPgI1uNa201gpb1LwYraKtQT+4m9hxxz3b/f2MPXeKyyKc0JmHGuc39ePiq+pntOa5n20Ge+8TjHG6+3/wZAAD//7fOtX01CwAA
  ```
</details>
<br/>

## 6. Delete the Repository
When a repository is deleted, the resources that the Repository Controller created will also be deleted.

Delete the Repository:
```
kubectl delete repository l7-gw-myapis
```

Then try to inspect l7-gw-myapis-repository-main again:
```
kubectl get secret l7-gw-myapis-repository-main
```

Here is an example of the previous command's output:
```
Error from server (NotFound): secrets "l7-gw-myapis-repository-main" not found
```

# Start [Lab Exercise 5](./lab-exercise5.md)
