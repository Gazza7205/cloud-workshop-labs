# Lab Exercise 2

1. [Prerequisites](#1-prerequisites)
1. [Overview](#2-overview)
1. [Change Directory](#3-change-directory)
1. [Copy License](#4-copy-license)
1. [Deploy the Layer7 Operator](#5-deploy-the-layer7-operator)
1. [Tail the Layer7 Operator Logs](#6-tail-the-layer7-operator-logs)
1. [Deploy a Layer7 API Gateway](#7-deploy-a-layer7-api-gateway)
1. [Inspect Resources](#8-inspect-resourcesw)
1. [Inspect the Gateway Custom Resource](#9-inspect-the-gateway-custom-resource)
1. [Update the Gateway Custom Resource](#10-update-the-gateway-custom-resource)
1. [Remove the Gateway Custom Resource](#11-remove-the-gateway-custom-resource)

## 1. Prerequisites

Please make sure you've completed the steps [here](./readme.md) before beginning this exercise.

## 2. Overview

Kubernetes operators automate tasks traditionally performed by a human operator of an application. Kubernetes operators should have the same level of deployment, behavior and troubleshooting expertise as a human operator when automating those tasks.

Kubernetes [operators](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) are Kubernetes extensions created using the [Operator SDK](https://github.com/operator-framework/operator-sdk). They make use of custom resources to manage applications and their components adhering to the Kubernetes principle of control loops. A control loop constantly observes the desired state of resources, analyzes the actual state of those resources, and executes actions to synchronize the current state with the desired state as necessary.

The [Layer7 Operator](https://github.com/CAAPIM/layer7-operator/wiki/Getting-Started) has expert knowledge of Layer7 products, and in the preview release, it makes use of [gateway](https://github.com/CAAPIM/layer7-operator/wiki/Gateway-Custom-Resource) and [repository](https://github.com/CAAPIM/layer7-operator/wiki/Repository-Custom-Resource) custom resources to automate the deployment, configuration and management of Layer7 API Gateways using static or dynamic config-as-code in the form of Graphman bundles from different sources of truth including git repositories or artifact repositories (or optionally backed by a MySQL database).

In this exercise, we will deploy the Layer7 Operator. We will then deploy a gateway custom resource to deploy and scale a gateway using the Layer7 Operator.

[Lab Exercise 2 Recording](https://youtu.be/grVKTUTavA8)

## 3. Change Directory

Assuming that you're currently in the folder you created for the workshop, and you've downloaded and uncompressed the labs repository to that folder, then change to the labs repository folder now:

```
cd cloud-workshop-labs-main
```

## 4. Copy License

Copy the Gateway v11.x license file (license.xml) to [`./exercise2-resources/`](./exercise2-resources/)

<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  cp ../license.xml ./exercise2-resources
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  copy ..\license.xml .\exercise2-resources
  ```
</details>
<br/>

## 5. Deploy the Layer7 Operator

This lab will deploy the Layer7 Operator using `kubectl` commands. It can also be deployed using [Helm](https://github.com/CAAPIM/layer7-operator/tree/main/charts/layer7-operator), [Operator Hub](https://operatorhub.io/operator/layer7-operator) and [Openshift](https://docs.openshift.com/container-platform/4.15/operators/understanding/olm-understanding-operatorhub.html).

<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  kubectl apply -f ./layer7-operator/rbac.yaml
  ```
  ```
  kubectl apply -f ./layer7-operator/operator.yaml
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  kubectl apply -f layer7-operator\rbac.yaml
  ```
  ```  
  kubectl apply -f layer7-operator\operator.yaml
  ```
</details>
<br/>

## 6. Tail the Layer7 Operator Logs

We can watch what the Layer7 Operator is doing to manage custom resources by watching its logs.

Open up a new terminal to tail the Layer7 Operator logs.

> _**Note: You may have to set your KUBECONFIG environment variable in the new terminal.**_

```
kubectl logs -f -l control-plane=controller-manager -c manager
```

## 7. Deploy a Layer7 API Gateway

We can tell the Layer7 Operator to deploy a Layer7 API Gateway by creating a new Gateway custom resource that describes the Layer7 API Gateway deployment to the Layer7 Operator.

First, create a Kubernetes secret with your Gateway v11.x license:
<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  kubectl create secret generic gateway-license --from-file=./exercise2-resources/license.xml
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  kubectl create secret generic gateway-license --from-file=exercise2-resources\license.xml
  ```
</details>
<br/>

Then, create a Gateway custom resource (or CR). Be sure to watch the Layer7 Operator's logs as you do this:
<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  kubectl apply -f ./exercise2-resources/gateway.yaml
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  kubectl apply -f exercise2-resources\gateway.yaml
  ```
</details>
<br/>

## 8. Inspect Resources

Inspect the resources that the Layer7 Operator created:

```
kubectl get all
```

## 9. Inspect the Gateway Custom Resource

Inspect the Gateway custom resource, and notice how its status has been updated by the Layer7 Operator:

```
kubectl get gateways
```
```
kubectl get gateway ssg -oyaml
```

## 10. Update the Gateway Custom Resource

Now lets make a change to the Gateway custom resource to see how the Layer7 Operator responds. Let's update its replicas from 1 to 2 to deploy a second gateway:

```
kubectl edit gateway ssg
```
Change `replicas: 1` to `replicas: 2`, and save and exit the editor.

Observe the second gateway pod:
```
kubectl get pods
```

## 11. Remove the Gateway Custom Resource

```
kubectl delete gateway ssg
```

# Start [Lab Exercise 3](./lab-exercise3.md)
