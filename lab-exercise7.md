
# Lab Exercise 7

1. [Prerequisites](#1-prerequisites)
2. [Overview](#2-overview)
3. [Message-Completed Global Policy Fragment](#3-message-completed-global-policy-fragment)
4. [Configure the Gateway](#4-configure-the-gateway)
5. [Update the Gateway](#5-update-the-gateway)
6. [Call Test Services](#6-call-test-services)
7. [Monitor the Gateway](#7-monitor-the-gateway)

## 1. Prerequisites

Please make sure you've completed the steps [here](./readme.md) and have completed [Lab Exercise 6](./lab-exercise6.md) before beginning this exercise.

## 2. Overview
In this exercise we will make use of the Gateway Telemetry Metric assertion to measure a custom metric. As noted in exercise 6, all the test services take a query parameter which denote the organization to which client (caller) belongs to. We will use that parameter to monitor the usage of APIs by organization.

## 3. Message-Completed Global Policy Fragment
We will use the Telemetry Metric assertion in the message-completed global policy fragment to create a custom `usage_by_org` metric with org, service_name, serviceOid and serviceUrl attributes.

Create a secret containing the policy bundle:
<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  kubectl create secret generic graphman-otel-message-complete --from-file=./exercise7-resources/otel_message_complete.json
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  kubectl create secret generic graphman-otel-message-complete --from-file=exercise7-resources\otel_message_complete.json
  ```
</details>
<br/>

The policy and assertion will appear as follows:

<kbd><img src="https://github.com/Gazza7205/cloud-workshop-labs/assets/59958248/c5d0f49a-5a12-46c8-9c9b-ad2a03a38a15" /></kbd>

## 4. Configure the Gateway
Continue using the Gateway custom resource file from lab exercise 6 [exercise6-resources/gateway.yaml](./exercise6-resources/gateway.yaml)

Add the new bundle by _**uncommenting lines 35 - 37**_:
```yaml
...
    bundle:
    - type: graphman
      source: secret
      name: graphman-otel-test-services
    - type: graphman
      source: secret
      name: graphman-otel-message-complete
    bootstrap:
...
```

## 5. Update the Gateway
Apply the changes made to Gateway custom resource. The Layer7 Operator will then reconcile the changes. Don't forget to update your Gateway name if you are using the gateway in the exercise 7 folder

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

Check the status of the ssg pod:
```
kubectl get pods
```

And wait until 2/2 containers in the ssg pod are READY. For example:
```
NAME                                                  READY   STATUS      RESTARTS       AGE
api-requests-5bvx2                                    0/1     Completed   0              5m38s
layer7-operator-controller-manager-7c996ccfb6-9qsw6   2/2     Running     1 (108m ago)   109m
ssg-56ff97b54d-nsx86                                  2/2     Running     0              116s
```

## 6. Call Test Services
We will reuse the job created in lab exercise 6 to generate some load and emit our new metric.

First, delete the job that was created in lab exercise 6:
```
kubectl delete job api-requests
```

Then, create the job again:
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

## 7. Monitor the Gateway
1. Login into [Grafana](https://grafana.brcmlabs.com/) (using credentials found [here](https://github.com/CAAPIM/cloud-workshop-labs-environment/blob/main/cloud-workshop/environment.txt).
2. Click **Dashboards** on the left menu
3. Expand the Layer7 Folder
4. Click on **Gateway Dashboard**
5. Select your gateway deployment (e.g. workshopuser99-ssg) from the **Gateway Deployment** dropdown field at the top of the page.
6. Scroll down to the bottom of the dashboard to see **Usage by Org**

![dashboard](./exercise7-resources/dashboard.png)


# Start [Lab Exercise 8](./lab-exercise8.md)
