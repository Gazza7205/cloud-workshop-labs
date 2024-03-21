
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

Open the OpenTelemetry Collector custom resource file here, [`./exercise6-resources/collector.yaml`](./exercise6-resources/collector.yaml).

On line 4, replace `(n)` with your workshop namespace number (e.g. workshopuser99-eck):
```yaml
...
metadata:
  name: workshopuser99-eck
spec:
...
```

On line 19, replace `(n)` with your workshop namespace number (e.g. workshopuser99-ssg):
```yaml
...
    processors:
      batch:
      resource:
        attributes:
        - key: layer7gw.name
          value: "workshopuser99-ssg"
          action: upsert
    exporters:
...
```

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

Open the OpenTelemetry Instrumentation custom resource file here, [`./exercise6-resources/instrumentation.yaml`](./exercise6-resources/instrumentation.yaml).

On line 8, replace `(n)` with your workshop namespace number (e.g. workshopuser99-ssg):
```yaml
...
spec:
  env:
    - name: OTEL_SERVICE_NAME
      value: workshopuser99-ssg
    - name: OTEL_METRICS_EXPORTER
...
```

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

First, add OpenTelemetry related cluster wide properties by _**uncommenting lines 105 - 110**_ (the other related cluster wide properties will be used in a later lab exercise).

```yaml
...
        - name: audit.setDetailLevel.FINE
          value: 152 7101 7103 9648 9645 7026 7027 4155 150 4716 4114 6306 4100 9655 150 151 11000 4104
        - name: otel.serviceMetricEnabled
          value: "true"
        - name: otel.metricPrefix
          value: l7_
        - name: otel.resourceAttributes
          value: k8s.container.name,k8s.pod.name
        # - name: otel.traceEnabled
        #   value: "true"
...
```

Next, disable auto instrumentation of all libraries except JDBC and JVM runtime-metrics by _**uncommenting lines 105 - 110**_ (go [here](https://opentelemetry.io/docs/languages/java/automatic/configuration/#suppressing-specific-agent-instrumentation) for a list of libraries that the agent can auto-instrument).

```yaml
...
      - -Dotel.instrumentation.common.default-enabled=false
      - -Dotel.instrumentation.opentelemetry-api.enabled=true
      - -Dotel.instrumentation.runtime-metrics.enabled=true
      - -Dotel.instrumentation.jdbc.enabled=true
      - -Dotel.instrumentation.jdbc-datasource.enabled=true
    listenPorts:
...
```

Then, add the Graphman bundle by _**commenting out line 30 and uncommenting lines 31 - 34**_.

```yaml
...
        cpu: 2
    # bundle: []
    bundle:
    - type: graphman
      source: secret
      name: graphman-otel-test-services
    # - type: graphman
...
```

Finally, add OpenTelemetry annotations by _**uncommenting lines 11 - 14**_. At the same time, _**replace `(n)` with your workshop namespace number on line 12 (e.g. workshopuser99-eck)**_.

```yaml
...
  app:
    annotations:
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
1. Login into [Kibana](https://kibana.brcmlabs.com/) (using credentials found [here](https://github.com/CAAPIM/cloud-workshop-labs-environment/blob/main/cloud-workshop/environment.txt).
1. Click the on **Analytics** tile on the Home page
1. Click the **Dashboard** tile on the Analytics page
1. Click the **Layer7 Gateway Dashboard** link on the Dashboards page
1. Select and include your gateway (e.g. workshopuser99-ssg) from the **Gateway** dropdown field.
1. You should be able to see service and runtime metrics for your gateway:

![dashboard](./exercise6-resources/dashboard.png)


# Start [Lab Exercise 7](./lab-exercise7.md)
