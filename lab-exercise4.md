# Lab Exercise 4
This exercise introduces the Repository Custom Resource. By the end should have a basic understanding of how to use Repositories with the Gateway. [See other exercises](./readme.md#lab-exercises).

### This exercise requires pre-requisites
Please perform the steps [here](./readme.md#before-you-start) to configure your environment if you haven't done so yet. This exercise follows on from [exercise 2](./lab-exercise2.md), make sure you've cloned this repository and added a Gateway v11.x license to the correct folder

## Key concepts
- [Repository Custom Resource](#the-repository-custom-resource)
- [Configuring Repositories](#configuring-repositories)
- [Create Repository](#create-repository)
- [Inspect Repository](#inspect-repository)
- [Delete Repository](#delete-repository)

### The Repository Custom Resource
The repository custom resource reconciles external Git repositories (or bundles that can be downloaded via HTTP; e.g. like might be stored in a solution like Artifactory) with the Layer7 Operator. The Repository Controller is responsible for ensuring that the latest commit is always available to be applied to Gateways. In the following sections we will dive deeper into how that happens.

Repository example (branch)
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

### Configuring Repositories
The above example repository will stay up-to-date with the main branch of https://github.com/Gazza7205/l7GWMyAPIs.

This is great for non-critical environments where downtime does not impact critical services. Mission critical environments should be idempotent, using tags is a significantly better approach to achieve this. Tags effectively represent a snapshot of Git repo from a specific point in time, that as part of a release cycle can undergo intensive testing.

Repository example (tag)
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
### Create Repository
Let's create a basic repository custom resource and inspect what happens.

1. Tail the Layer7 Operator logs in a separate terminal (you may have to set your KUBECONFIG environment variable in the new terminal)
```
kubectl logs -f -l control-plane=controller-manager -c manager
```

2. Create the Repository
<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  kubectl apply -f ./exercise3-resources/apis-repository.yaml
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  kubectl apply -f exercise3-resources\apis-repository.yaml
  ```
</details>
<br/>

### Inspect Repository
When a repository is created the repository controller clones from the provided endpoint and attempts to create a Kubernetes secret with the repository contents in graphman bundle format.

- Get the Repository
```
kubectl get repository l7-gw-myapis -oyaml
```

output
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

- Inspect the storage secret
If a repository is less than 1mb in size when in compressed json format the repository controller will attempt to save it in a Kubernetes Secret.
<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  kubectl get secret l7-gw-myapis-repository-main -ojsonpath="{.data['l7-gw-myapis\.gz']}" | base64 -d | gzip -d
  ```
  Output:
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
  Output (base64 encoded gzipped file; to see decoded and unzipped file contents check out the Linux/MacOS example above):
  ```
  H4sIAAAAAAAA/+yVb0/jRhDGv4o1r534v9d2FZ3CXS7HCbUUQo7jfDqtd8exxdrretc4EeK7VyakAY4CL6qqlXi1UmaeeXZ25hdfQ4/ZtClPsb0qGSpIvl3DSpYcEoh8349D4tAMXRpkju/ZgcMznvOcYBgFYEIuBcf2mOoCErCqzbQpFZhQ0wohgRNU2pg2peGACS0qKTpdynqXTptyCDRSlGwDyTWsKwEJpJ1te+zduhLGFbaqlPUkBWdsp2BgzSQv69UkhbPFx1GUwrvbbEzrrapXTXJ8W89YV6JWyRFpJikUWjeJZfV9PxZ0gy3RyIoxk5XVK2vrn8Kdolf3FIoVWFE1XldCSdqMZbsaJK5tu5bj/iXdXcIwDGN/kakQxnCeKbrCSQon+EdXtsgf5u81R6RJTlEvaVvSTODjpIeJB1Rh6M/WTYtqeCND6basV0squsGLzpcqm0err+cHzeGH2SQF6/l6O9eFPEX9qJjaLscP1SAr85L9uKLtEwW3xawX2thbHtZMdPyFPrfTnHclf9xhnBMn9LIRdwgd+S5GozgjwSgKAkbDPCTMjp6/5BP+d9G76T3cLWu/XLsA3JiA9dAlh0S3HZpQoS4kV1MhZD/8+g3mswWYcPzb6e1xtoDvJuiWsrJezXbanAqFJvRKHbeSDRP9OcgKZJeqqyAByu0wpkgyO3JCL8yJ5/l5TsIsjrk9vALnJM4iB27M19FMnPD1NLt/R7P7RvO/QfPhG83/IZpN+DA7mi1m/wDWYeZiEASBE/PQzSM/p8y1CXWyyA+py10eeXEQMHYf6zhyGXMQiRfGLGQ0oISigz7lUUa9OH4Raz1gXSDl2KonwR4S9vE3vu+t8yfaciY58hNUjazVqyjf5R5IvvmZ8+JivtywXl6i91mw86Vg3u8d/XRis/dBkc3X8uLLx8uL88/u1y9r5+L81/jF/4Kd33tZa6z1YtPgI1uNa201gpb1LwYraKtQT+4m9hxxz3b/f2MPXeKyyKc0JmHGuc39ePiq+pntOa5n20Ge+8TjHG6+3/wZAAD//7fOtX01CwAA
  ```
</details>
<br/>

### Delete Repository
When a repository is deleted, the resources that the repository controller created will also be removed.

- Delete the repository
```
kubectl delete repository l7-gw-myapis
```
- Try inspect l7-gw-myapis-repository-main again
```
kubectl get secret l7-gw-myapis-repository-main
```
output
```
Error from server (NotFound): secrets "l7-gw-myapis-repository-main" not found
```

### Start [Exercise 4](./lab-exercise4.md)