
# Lab Exercise 6

1. [Prerequisites](#1-prerequisites)
1. [Overview](#2-overview)
1. [Create OpenTelemetry Collector Custom Resource](#3-create-opentelemetry-collector-custom-resource)
1. [Create OpenTelemetry Instrumentation Custom Resource](#4-create-opentelemetry-instrumentation-custom-resource)
1. [Deploy Test Services](#5-deploy-test-services)
1. [Configure the Gateway](#6-configure-the-gateway)
1. [Update the Gateway](#7-update-the-gateway)
1. [Call Test Services](#8-call-test-services)
1. [Monitor the Gateway](#9-monitor-the-gateway)

## 1. Prerequisites

Please make sure you've completed the steps [here](./readme.md) and have completed [Lab Exercise 5](./lab-exercise5.md) before beginning this exercise.

## 2. Overview

In this exercise you will observe your Gateway using OpenTelemetry.

## 3. Create OpenTelemetry Collector Custom Resource

The [OpenTelemetry Operator](https://opentelemetry.io/docs/kubernetes/operator/) has already been deployed to the lab exercise's shared Kubernetes cluster. Just like the Layer7 Operator manages Gateway and Repository custom resources. The OpenTelemetry Operator manages OpenTelemetry Collector custom resources. This section will create an OpenTelemetry customer resource, and the OpenTelemetry Operator will correspondingly deploy an OpenTelemetry Collector as a sidecar to the gateway pod. The OpenTelemetry Collector collects, filters and forwards metrics, traces and logs emitting by an OpenTelemetry Agent that will be injected into the gateway and the OpenTelemetry SDK that is used by the gateway.

Create the OpenTelemetry Collector custom resource:

<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  kubectl apply -f ./exercise6-resources/collector.yaml
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  kubectl apply -f exercise6-resources\collector.yaml
  ```
</details>
<br/>

## 4. Create OpenTelemetry Instrumentation Custom Resource

The OpenTelemetry Operator also manages [OpenTelemetry Instrumentation](https://github.com/open-telemetry/opentelemetry-operator?tab=readme-ov-file#opentelemetry-auto-instrumentation-injection) custom resources, and uses them to automatically instrument workloads, like the gateway, by injecting OpenTelemetry Agents and related configuration.

View the OpenTelemetry Instrumentation custom resource file here, [`./exercise6-resources/instrumentation.yaml`](./exercise6-resources/instrumentation.yaml).

Create the OpenTelemetry Instrumentation custom resource:

<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  kubectl apply -f ./exercise6-resources/instrumentation.yaml
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  kubectl apply -f exercise6-resources\instrumentation.yaml
  ```
</details>
<br/>

## 5. Deploy Test Services

We will create a Kubernetes secret with a Graphman bundle that will bootstrap the following test services. These will be used to generate metrics and demonstrate other concepts during this workshop.

**Test Services**

- **/test1** - Always succeeds. Calls another service /echotest and returns result from it.
- **/test2** - Always generates a policy failure.
- **/test3** - Always generates a routing failure.
- **/test4** - Always succeeds. No routing.    
- **/test5** - Takes two query parameters as input and calculates age (years elapsed). It has an error that needs to be diagnosed and fixed.
  - **dob** - Date of Birth - Default format dd/MM/yyyy
  - **format** (optional) - Specify the format of dob
- **/echotest** - Returns system date and time.

Create the Graphman bundle secret:
<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  kubectl create secret generic graphman-otel-test-services  --from-file=./exercise6-resources/otel_test_services.json
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  kubectl create secret generic graphman-otel-test-services  --from-file=exercise6-resources\otel_test_services.json
  ```
</details>
<br/>

## 6. Configure the Gateway

We can now configure our Gateway custom resource for OpenTelemetry and the Graphman bundle secret.

Open the Gateway custom resource file here, [`./exercise6-resources/gateway.yaml`](./exercise6-resources/gateway.yaml).

First, configure your Gateway name. You will use this as a filter in Grafana later on.

Update metadata.name
```yaml
apiVersion: security.brcmlabs.com/v1
kind: Gateway
metadata:
  name: <workshopuser(n)-ssg>
...
```
example
```yaml
apiVersion: security.brcmlabs.com/v1
kind: Gateway
metadata:
  name: workshopuser1-ssg
...
```

Next, Add OpenTelemetry related cluster wide properties by _**uncommenting lines 102 - 116**_ .

```yaml
...
# - name: otel.enabled
#   value: "true"
# - name: otel.serviceMetricEnabled
#   value: "true"
# - name: otel.traceEnabled
#   value: "true"
# - name: otel.metricPrefix
#   value: l7_
# - name: otel.traceConfig
#   value: |
#     {
#       "services": [
#         {"resolutionPath": ".*"}
#       ]
#     }
...
```

Next, configure the Gateway via system properties to work with the OpenTelemetry Agent by _**uncommenting lines 132 - 137**_ (go [here](https://opentelemetry.io/docs/languages/java/automatic/configuration/#suppressing-specific-agent-instrumentation) for a list of libraries that the agent can auto-instrument).

```yaml
...
# otel.instrumentation.common.default-enabled=true
# otel.instrumentation.opentelemetry-api.enabled=true
# otel.instrumentation.runtime-metrics.enabled=true
# otel.instrumentation.runtime-telemetry.enabled=true
# otel.instrumentation.opentelemetry-instrumentation-annotations.enabled=true
# otel.java.global-autoconfigure.enabled=true
...
```

Then, add the Graphman bundle by _**commenting out line 30 and uncommenting lines 31 - 34**_.

```yaml
...
# bundle: []
  bundle:
  - type: graphman
    source: secret
    name: graphman-otel-test-services
...
```

Finally, add OpenTelemetry annotations by _**uncommenting lines 11 - 14**_. At the same time, _**replace `(n)` with your workshop namespace number on line 12 (e.g. workshopuser99-eck)**_.

```yaml
...
app:
  podAnnotations:
    sidecar.opentelemetry.io/inject: "workshopuser99-eck"
    instrumentation.opentelemetry.io/inject-java: "true"
    instrumentation.opentelemetry.io/container-names: "gateway"
  replicas: 1
...
```

## 7. Update the Gateway

Now that we've configured our Gateway custom resource to make Gateway more observable using OpenTelemetry, we can apply the updated manifest to Kuberenetes.

<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  kubectl apply -f ./exercise6-resources/gateway.yaml
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  kubectl apply -f exercise6-resources\gateway.yaml
  ```
</details>
<br/>

## 8. Call Test Services
We'll now create a configmap containing a script that will call our test services in a Kubernetes Job.

Update the GATEWAY_HOSTNAME (line 9) in [api-request-configmap.yaml](./exercise6-resources/api-request-configmap.yaml). This should match the name that you gave your Gateway in the previous step

update GATEWAY_HOSTNAME
```yaml
  script: |
    #!/bin/bash
    
    GATEWAY_HOSTNAME=workshopuser(n)-ssg
```
example
```yaml
  script: |
    #!/bin/bash
    
    GATEWAY_HOSTNAME=workshopuser1-ssg
```

Create the configmap:
<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  kubectl apply -f ./exercise6-resources/api-request-configmap.yaml
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  kubectl apply -f exercise6-resources\api-request-configmap.yaml
  ```
</details>
<br/>

Create the job:
<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  kubectl apply -f ./exercise6-resources/test-services.yaml
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  kubectl apply -f exercise6-resources\test-services.yaml
  ```
</details>
<br/>

Watch the job run (making 1000 requests; with a 0 index):
```
kubectl logs -f job.batch/api-requests
```

## 9. Monitor the Gateway
1. Login into [Grafana](https://grafana.brcmlabs.com/) (using credentials found [here](https://github.com/CAAPIM/cloud-workshop-labs-environment/blob/main/cloud-workshop/environment.txt).
2. Click **Dashboards** on the left menu
3. Expand the Layer7 Folder
4. Click on **Gateway Dashboard**
5. Select your gateway deployment (e.g. workshopuser99-ssg) from the **Gateway Deployment** dropdown field at the top of the page.

You will notice that there are more than 1000 requests, this is because the Gateway calls itself to simulate routing. Those calls are also captured by the OTel integration.


![dashboard](./exercise6-resources/dashboard.png)


# Start [Lab Exercise 7](./lab-exercise7.md)
