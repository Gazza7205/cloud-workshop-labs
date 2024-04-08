# Lab Exercise 5

1. [Prerequisites](#1-prerequisites)
1. [Overview](#2-overview)
1. [Create Repository Custom Resources](#3-create-repository-custom-resources)
1. [Configure Repository References](#4-configure-repository-references)
1. [Singletons](#5-singletons)
1. [Update the Gateway Custom Resource](#6-update-the-gateway-custom-resource)
1. [Inspect the Gateway Custom Resource](#7-inspect-the-gateway-custom-resource)
1. [Inspect the Gateway Deployment](#8-inspect-the-gateway-deployment)
1. [Test the Gateway Deployment](#9-test-the-gateway-deployment)

## 1. Prerequisites

Please make sure you've completed the steps [here](./readme.md) and have completed [Lab Exercise 4](./lab-exercise4.md) before beginning this exercise.

## 2. Overview

This exercise combines the previous Layer7 Operator exercises into a more advanced example.

![Lab Exercise 5 Recording](https://youtu.be/6rH6LGDj0no)

## 3. Create Repository Custom Resources
There are three Repository custom resources defined here, [`./exercise5-resources/repositories/`](./exercise5-resources/repositories/). These make up an example framework that aims to break up more complex configuration into more manageable parts. Parts that can be managed separately by separate teams in separate repositories with different change life cycles. These are provided purely as an example, and to demonstrate related concepts during these lab exercises.

The same folder includes a secret for repository credentials (instead of including the credentials in the Repository custom resource manifests themselves) that will be created together with the Repository custom resources using Kustomize in the steps below.

First, if you're not still tailing the Layer7 Operator logs from the previous lab exercise, then start doing that now in a separate terminal (you may have to set your KUBECONFIG environment variable in the new terminal):
```
kubectl logs -f -l control-plane=controller-manager -c manager
```

Next, create the Repositories and associated secret using Kustomize:

<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  kubectl apply -k ./exercise5-resources/repositories/
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  kubectl apply -k exercise5-resources/repositories
  ```
</details>
<br/>

Finally, view the created Repositories:

```
kubectl get repositories
```

Here is an example of the previous command's output:
```
NAME                    AGE
l7-gw-myapis            67s
l7-gw-myframework       67s
l7-gw-mysubscriptions   67s
```

## 4. Configure Repository References

Now we will update our Gateway custom resource manifest to reference the Repositories that were just created. Repository references are used by the Gateway controller to reconcile the resulting Graphman bundles from our repositories to gateways. This is tracked using annotations that are applied to each gateway pod (in ephemeral mode) or deployment (when there is a MySQL database configured).

Open this file, [`./exercise5-resources/gateway.yaml`](./exercise5-resources/gateway.yaml), and add the Repository references (~ line 37):

```yaml
...
    singletonExtraction: false
    repositoryReferences:
    - name: l7-gw-myframework
      enabled: true
      type: static
      encryption:
        existingSecret: graphman-encryption-secret
        key: FRAMEWORK_ENCRYPTION_PASSPHRASE
    - name: l7-gw-myapis
      enabled: true
      type: dynamic
      encryption:
        existingSecret: graphman-encryption-secret
        key: APIS_ENCRYPTION_PASSPHRASE
    - name: l7-gw-mysubscriptions
      enabled: true
      type: dynamic
      encryption:
        existingSecret: graphman-encryption-secret
        key: SUBSCRIPTIONS_ENCRYPTION_PASSPHRASE
    initContainers:
...
```

Before we apply those changes, let's consider some of the Repository reference properties:

#### type
Repository references can be eithe static or dynamic.

- static
    - Applied by the Layer7 Operator using a managed dynamic initContainer
    - Applied statically via bootstrapping on gateway startup
    - Updates require gateway restarts
    - Useful for configuration that changes less frequently
    - Using tags is recommended!!
- dynamic
    - Applied by the Layer7 Operator using the Graphman API
    - Applied dynamically via the Graphman API to running gateways
    - Updates do not require gateway restarts
    - Useful for configuration that changes frequently
    - Includes support for singleton configurations
    - Zero downtime

#### encryption
Certain entities (like stored passwords) can be encrypted for secure storage. The encryption property allows us to provide a decryption key for the Graphman service. We will provide the key(s) using the `graphman-encryption-secret` Kubernetes secret referenced in the Gateway custom resource above.

Create the `graphman-encryption-secret` secret:
<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  kubectl create secret generic graphman-encryption-secret --from-env-file=./exercise5-resources/graphman-encryption-secret.env
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  kubectl create secret generic graphman-encryption-secret --from-env-file=exercise5-resources\graphman-encryption-secret.env
  ```
</details>
<br/>

## 5. Singletons

Singletons are Gateway Scheduled Tasks or JMS listeners that should only run on one Gateway. These don't require special support when deploying gateways backed by a shared MySQL database. However, they do need special support when deploying ephemeral gateways that don't share a database.

Notice the singletonExtraction property on line 36 in [`./exercise5-resources/gateway.yaml`](./exercise5-resources/gateway.yaml). Singleton extraction supports using singletons for ephemeral gateways by designating one gateway pod as a leader and only applying scheduled tasks and JMS listeners to that pod. This is currently only supported by dynamic repository references. 

## 6. Update the Gateway Custom Resource

We will now apply the above changes to the Gateway custom resource. Be sure to watch the Layer7 Operator logs that you are tailing to see it detect these changes.

<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  kubectl apply -f ./exercise5-resources/gateway.yaml
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  kubectl apply -f exercise5-resources\gateway.yaml
  ```
</details>
<br/>

This will trigger an update to your Gateway deployment with the addition of the static repository.

## 7. Inspect the Gateway Custom Resource

Let's take a look at the Gateway custom resource:
```
kubectl get gateway ssg -oyaml
```

Here is an example of the previous command's output (for just the status property):
```yaml
...
status:
  conditions:
  - lastTransitionTime: "2023-09-18T19:13:44Z"
    lastUpdateTime: "2023-09-18T19:13:44Z"
    message: Deployment has minimum availability.
    reason: MinimumReplicasAvailable
    status: "True"
    type: Available
  - lastTransitionTime: "2023-09-13T12:52:00Z"
    lastUpdateTime: "2023-09-23T13:21:43Z"
    message: ReplicaSet "ssg-74bc56d55c" has successfully progressed.
    reason: NewReplicaSetAvailable
    status: "True"
    type: Progressing
  gateway:
  - name: ssg-74bc56d55c-cgctb
    phase: Running
    ready: true
    startTime: 2023-09-23 13:27:34 +0000 UTC
  host: gateway.brcmlabs.com
  image: docker.io/caapim/gateway:11.0.00_CR1
  managementPod: ssg-74bc56d55c-cgctb
  ready: 1
  replicas: 1
  repositoryStatus:
  - branch: main
    commit: cd1e9692d78b15c7012137f6b1607d2207709509
    enabled: true
    endpoint: https://github.com/Gazza7205/l7GWMyFramework
    name: l7-gw-myframework
    secretName: graphman-repository-secret
    storageSecretName: l7-gw-myframework-repository-main
    type: static
  - branch: main
    commit: 8fc74669689abe781645dac214ebf26eb7480c78
    enabled: true
    endpoint: https://github.com/Gazza7205/l7GWMyAPIs
    name: l7-gw-myapis
    secretName: graphman-repository-secret
    storageSecretName: l7-gw-myapis-repository-main
    type: dynamic
  - branch: main
    commit: 9daef7d1286dd13b609ada39ff1d6aa624ff64da
    enabled: true
    endpoint: https://github.com/Gazza7205/l7GWMySubscriptions
    name: l7-gw-mysubscriptions
    secretName: graphman-repository-secret
    storageSecretName: l7-gw-mysubscriptions-repository-main
    type: dynamic
  state: Ready
  version: 11.0.00_CR1
```

## 8. Inspect the Gateway Deployment

First, let's take a look at the gateway deployment:

```
kubectl describe deployment ssg
```

Here is an example of the previous command's output (for just the Init Containers property):

```yaml
...
Init Containers:
  workshop-init:
   Image:        harbor.sutraone.com/mock/workshop-init:1.0.0
   Port:         <none>
   Host Port:    <none>
   Environment:  <none>
   Mounts:
     /opt/docker/custom from config-directory (rw)
  graphman-static-init-8551b0f587:
   Image:      docker.io/layer7api/graphman-static-init:1.0.1
   Port:       <none>
   Host Port:  <none>
   Environment:
     BOOTSTRAP_BASE:  /opt/SecureSpan/Gateway/node/default/etc/bootstrap/bundle/graphman/0
   Mounts:
     /graphman/config.json from ssg-repository-init-config (rw,path="config.json")
     /graphman/localref/l7-gw-myframework-repository-main from l7-gw-myframework-repository-main (rw)
     /graphman/secrets/l7-gw-myframework from graphman-repository-secret (rw)
     /opt/SecureSpan/Gateway/node/default/etc/bootstrap/bundle/graphman/0 from ssg-repository-bundle-dest (rw)
...
```

Next, let's look at the gateway pod:

```
kubectl get pods
```

Here is an example of the previous command's output:

```
NAME                                                  READY   STATUS    RESTARTS   AGE
layer7-operator-controller-manager-77bb65f7fb-87gv4   2/2     Running   0          4d16h
ssg-74bc56d55c-cgctb                                  1/1     Running   0          6m38s
```

_**Note: Wait for the ssg pod to show READY 1/1 before proceeding to the next step.**_

Use the ssg pod name output from the above command in the below command:
```
kubectl get pod <pod-name> -oyaml
```

Here is an example of the previous command's output (for just the metadata property):
```yaml
...
metadata:
  annotations:
    security.brcmlabs.com/l7-gw-myapis-dynamic: 8fc74669689abe781645dac214ebf26eb7480c78
    security.brcmlabs.com/l7-gw-mysubscriptions-dynamic: 9daef7d1286dd13b609ada39ff1d6aa624ff64da
  creationTimestamp: "2023-09-23T13:27:34Z"
  generateName: ssg-74bc56d55c-
  labels:
    app.kubernetes.io/created-by: layer7-operator
    app.kubernetes.io/managed-by: layer7-operator
    app.kubernetes.io/name: ssg
    app.kubernetes.io/part-of: ssg
    management-access: leader
    pod-template-hash: 74bc56d55c
...
```

The Layer7 Operator uses the dynamic repository checksums to keep gateway configuration in sync with repository configuration. We can trigger a dynamic gateway update by modifying one of the dynamic repository checksums. Edit the gateway pod and make a change to one of the dynamic repository checksums, and then save your change. Be sure to watch the Layer7 Operator logs that you are tailing to see it detect these changes.

Use the ssg pod name output from the above command in the below command:
```
kubectl edit pod <pod-name>
```

You should see the change event in the Layer7 Operator logs, and you should see that your change was reverted by the Layer7 Operator if you check your gateway pod's annotations again:
```
kubectl get pod <pod-name> -oyaml
```

## 9. Test the Gateway Deployment

Now, let's test our gateway by calling an API and connecting with Policy Manager to view the gateway's configuration that was applied using Repository references.

First, find the external IP address for the gateway service in your namespace:

```
kubectl get svc ssg
```

Here is an example of the previous command's output. In this example, the external IP address is **34.168.26.20**. Yours will be different.

```
NAME   TYPE           CLUSTER-IP     ***EXTERNAL-IP***    PORT(S)                         AGE
ssg    LoadBalancer   10.96.14.218   34.168.26.20         8443:32060/TCP,9443:30632/TCP   80s
```

Next, try calling an API on the gateway using your external IP address. For example:

```
curl -k -H "client-id: D63FA04C8447" https://<your-external-ip>:8443/api1
```

The API should respond like so:
```json
{
  "client" : "D63FA04C8447",
  "plan" : "plan_a",
  "service" : "hello api 1",
  "myDemoConfigVal" : "Deep Inside Config"
}
```

Finally, connect to your gateway with Policy Manager to view the statically and dynamically applied configuration:
```
User Name: admin
Password: 7layer
Gateway: <your-external-ip>
```

# Start [Lab Exercise 6](./lab-exercise6.md)


