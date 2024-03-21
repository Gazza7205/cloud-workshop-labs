
# Lab Exercise 8

1. [Prerequisites](#1-prerequisites)
1. [Overview](#2-overview)
1. [Enable Tracing on the Gateway](#3-enable-tracing-on-the-gateway)
1. [Update the Gateway](#4-update-the-gateway)
1. [Call Test Service](#5-call-test-service)
1. [View Trace in Jaeger](#6-view-trace-in-jaeger)

## 1. Prerequisites

Please make sure you've completed the steps [here](./readme.md) and have completed [Lab Exercise 7](./lab-exercise7.md) before beginning this exercise.

## 2. Overview

In this exercise we will use OpenTelemetry tracing to help diagnose a service failure.

## 3. Enable Tracing on the Gateway

To be practically useful, we need to be able to selectively enable and filter tracing to have a controlled impact on gateway and OpenTelemetry backend processing and storage resource utilization.

The `otel.traceEnabled` cluster-wide property can be used to enable and disable tracing.

The `otel.traceConfig` cluster-wide property can be used to control which services, assertions and context variables will be traced. It can also filter tracing to requests sent from a specific client IP address.

Continue using the Gateway custom resource file from lab exercise 6 [exercise6-resources/gateway.yaml](./exercise6-resources/gateway.yaml).

Enable tracing by _**uncommenting lines 111 - 112**_:
```yaml
...
        - name: otel.traceEnabled
          value: "true"
        - name: otel.traceConfig
          value: |
              {
                "services": [
                  {"url": ".*/test.*"}
                ],
                "contextVariables": {
                  "assertions" : [".*"]
                }
              }
    system:
...
```

## 4. Update the Gateway
Apply the changes made to Gateway custom resource. 

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

When only making cluster-wide property changes in this way, the gateway pod will not restart to pick up the changes. For now, we can delete the gateway pod, and Kuberenetes will recreate it with the new cluster-wide properties. As you've already seen in previous lab exercises, using the Layer7 Operator with Repository custom resources may be a better way to promote changes like these.

```
kubectl delete pod -l app.kubernetes.io/name=ssg
```

Check the status of the ssg pods:
```
kubectl get pods
```

And wait until there is just one ssg pod with 2/2 containers READY. For example:
```
NAME                                                  READY   STATUS      RESTARTS       AGE
api-requests-5bvx2                                    0/1     Completed   0              5m38s
layer7-operator-controller-manager-7c996ccfb6-9qsw6   2/2     Running     1 (108m ago)   109m
ssg-56ff97b54d-nsx86                                  2/2     Running     0              116s
```

## 5. Call Test Service

We will call this test service to generate a trace:

- **/test5** - Takes two query parameters as input and calculates age (years elapsed). It has an error that needs to be diagnosed and fixed.
  - **dob** - Date of Birth - Default format dd/MM/yyyy
  - **format** (optional) - Specify the format of dob

<kbd><img src="https://github.com/Gazza7205/cloud-workshop-labs/assets/59958248/dc9343e8-b452-489e-bc83-7201a30a6d51" /></kbd>

First, find the external IP address for the gateway service in your namespace:

```
kubectl get svc ssg
```

Here is an example of the previous command's output. In this example, the external IP address is **34.168.26.20**. Yours will be different.

```
NAME   TYPE           CLUSTER-IP     ***EXTERNAL-IP***    PORT(S)                         AGE
ssg    LoadBalancer   10.96.14.218   34.168.26.20         8443:32060/TCP,9443:30632/TCP   80s
```

Next, try call the test service on the gateway using your external IP address. For example:

```
curl -k https://<your-external-ip>:8443/test5
```

The API should respond like so:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
    <soapenv:Body>
        <soapenv:Fault>
            <faultcode>soapenv:Server</faultcode>
            <faultstring>Policy Falsified</faultstring>
            <faultactor>https://localhost:8443/test5</faultactor>
            <detail>
                <l7:policyResult status="Error in Assertion Processing" xmlns:l7="http://www.layer7tech.com/ws/policy/fault"/>
            </detail>
        </soapenv:Fault>
    </soapenv:Body>
</soapenv:Envelope>
```

## 6. View Trace in Jaeger
1. Open [Jaeger](https://jaeger.brcmlabs.com/).
1. Select the your service under Service dropdown (workshopuser(n)-ssg)
1. Search for and select `age` in the **Operation** dropdown field (the service name is "age" and the service URL is "/test5").
1. Click on **Find Traces**
1. Click on one of the traces in the search result set.
1. Explore the trace spans and check for errors. In particular, you should find a Javascript error like follows:

![trace](./exercise8-resources/trace.png)

# Start [Lab Exercise 9](./lab-exercise9.md)
