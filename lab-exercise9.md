# Lab Exercise 9

1. [Prerequisites](#1-prerequisites)
1. [Overview](#2-overview)
1. [Create Kubernetes Secret](#3-create-kubernetes-secret)
1. [Create Resources](#4-create-resources)
1. [Configure the Gateway](#5-configure-the-gateway)
1. [Update the Gatewayx](#6-update-the-gateway)
1. [Inspect the Gateway](#7-inspect-the-gateway)
1. [Test your Gateway Deployment](#8-test-your-gateway-deployment)

## 1. Prerequisites

Please make sure you've completed the steps [here](./readme.md) and have completed [Lab Exercise 8](./lab-exercise8.md) before beginning this exercise.

## 2. Overview

This exercise introduces how to synchronize external Kubernetes secrets with stored passwords on gateways.

## 3. Create Kubernetes Secret

Kubernetes secrets are stored as base64 encoded strings without any encryption. Graphman accepts encrypted values and decrypts them with either the clusterPassphrase or a user supplied passphrase.

First, encrypt a value (there may be a warning about the key deriviation which we will ignore for now):
<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  echo -n "myothersupersecretvalue" | openssl enc -aes-256-cbc -md sha256 -pass pass:7layer -a
  ```

  Here is an example of the previous command's output:
  ```
  U2FsdGVkX19+coRzCf5pI1wvM03aDsehAyZBhXQFvZKE+70ZOuzSfZU/xvUSiz+N
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  echo|set /p="myothersupersecretvalue"|"C:\Program Files\Git\usr\bin\openssl" enc -aes-256-cbc -md sha256 -pass pass:7layer -a
  ```

  Here is an example of the previous command's output:
  ```
  U2FsdGVkX19+coRzCf5pI1wvM03aDsehAyZBhXQFvZKE+70ZOuzSfZU/xvUSiz+N
  ```
</details>
<br/>

Next, create the Kubernetes secret with that encrypted value (i.e. replace `<encrypted-value>` in the below command with the outputed value of the previous command):
```
kubectl create secret generic mysupersecrets --from-literal=mysupersecret1=mysupersecretvalue --from-literal=mysupersecret2=<encrypted-value>
```

## 4. Create Resources

This step uses Kustomize to create a Kubernetes secret with a Graphman bundle with a service that can return stored password values from the gateway (for demonstrative purposes).

It also integrates Kubernetes with GCP Secret Manager via the [external secrets operator](https://external-secrets.io/latest/) (so the external secrets operator can create Kubernetes secrets for GCP Secret Manager secrets). GCP Secret Manager is just one of [many external secret management providers](https://external-secrets.io/latest/provider/aws-secrets-manager/) supported by the external secrets operator.

<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  kubectl apply -k ./exercise9-resources
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  kubectl apply -k exercise9-resources
  ```
</details>
<br/>

In a few moments, you can find a Kubernetes secret created by the external secrets operator from a GCP Secret Manager secret:

```
kubectl get secret database-credentials-gcp -oyaml
```

## 5. Configure the Gateway

We will now configure the Gateway custom resource, [`exercise9-resources/gateway.yaml`](./exercise9-resources/gateway.yaml), to include the Graphman bundle secret and the external secrets.

First, under line 33, insert the new bundle (i.e `graphman-secret-reader-bundle`):
```yaml
...
    bundle:
      - type: restman
        source: secret
        name: restman-cluster-property-bundle
      - type: graphman
        source: secret
        name: graphman-cluster-property-bundle
      - type: graphman
        source: secret
        name: graphman-secret-reader-bundle
    bootstrap:
...
```

Then, on line 26, remove the array brackets (e.g. `[]`), and below that line add the external secret references:
```yaml
...
        cpu: 2
    externalSecrets:
    - name: database-credentials-gcp
      enabled: true
      description: GCP Database credentials
      variableReferencable: true
    - name: mysupersecrets
      enabled: true
      description: top secret
      variableReferencable: true
      encryption:
        passphrase: 7layer
        existingSecret: ""
    - name: private-key-secret
      enabled: true
      description: a private key
      variableReferencable: false
    bundle:
...
```

## 6. Update the Gateway

First, if you're not still tailing the Layer7 Operator logs from previous lab exercises, then start doing that now in a separate terminal (you may have to set your KUBECONFIG environment variable in the new terminal).

```
kubectl logs -f -l control-plane=controller-manager -c manager
```

Then, apply the above changes to the Gateway custom resource. Be sure to watch the Layer7 Operator logs that you are tailing to see it detect these changes.

<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  kubectl apply -f ./exercise9-resources/gateway.yaml
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  kubectl apply -f exercise9-resources\gateway.yaml
  ```
</details>
<br/>

## 7. Inspect the Gateway

Now, let's look at the gateway pod:

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
    security.brcmlabs.com/external-secret-database-credentials-gcp: 0935885ac45ab667fa9a8c30e040e867eebafd6c
    security.brcmlabs.com/external-secret-mysupersecrets: 2a9fa4811aa7037693b05795c202237862b10579
    security.brcmlabs.com/external-secret-private-key-secret: a52bffc4382b47978308e72467b01e29b94f7c33
    security.brcmlabs.com/l7-gw-myapis-dynamic: 8fc74669689abe781645dac214ebf26eb7480c78
    security.brcmlabs.com/l7-gw-mysubscriptions-dynamic: 9daef7d1286dd13b609ada39ff1d6aa624ff64da
  creationTimestamp: "2023-09-25T12:59:01Z"
  generateName: ssg-6c56b6944b-
  labels:
    app.kubernetes.io/created-by: layer7-operator
    app.kubernetes.io/managed-by: layer7-operator
    app.kubernetes.io/name: ssg
    app.kubernetes.io/part-of: ssg
    management-access: leader
    pod-template-hash: 6c56b6944b
...
```

The Layer7 Operator uses the external secret checksums to keep gateway configuration in sync with external secrets. We can trigger a dynamic gateway update by modifying one of the external secret checksums. Edit the gateway pod and make a change to one of the external secret checksums, and then save your change. Be sure to watch the Layer7 Operator logs that you are tailing to see it detect these changes.

Use the ssg pod name output from the above command in the below command:
```
kubectl edit pod <pod-name>
```

You should see the change event in the Layer7 Operator logs, and you should see that your change was reverted by the Layer7 Operator if you check your gateway pod's annotations again:
```
kubectl get pod <pod-name> -oyaml
```

## 8. Test your Gateway Deployment

First, find the external IP address for the gateway service in your namespace:

```
kubectl get svc ssg
```

Here is an example of the previous command's output. In this example, the external IP address is **34.168.26.20**. Yours will be different.

```
NAME   TYPE           CLUSTER-IP     ***EXTERNAL-IP***    PORT(S)                         AGE
ssg    LoadBalancer   10.96.14.218   34.168.26.20         8443:32060/TCP,9443:30632/TCP   80s
```

Next, try call the secrets service on the gateway using your external IP address. For example:

```
curl -k https://<your-external-ip>:8443/secrets
```

The API should respond like so:
```json
{
  "gcp-credentials": {
     "database_username": "gateway",
     "database_password": "7A6j7EyTVPKplTPh"
   },
  "local-credentials": {
    "mysupersecret1": "mysupersecretvalue",
    "mysupersecret2" "myothersupersecretvalue"
  }
}
```

Finally, connect to your gateway with Policy Manager to view the stored passwords:

```
User Name: admin
Password: 7layer
Gateway: <your-external-ip>
```




