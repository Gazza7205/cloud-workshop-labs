# Lab exercise 8
This exercise introduces how to use external kubernetes secrets as Gateway Stored Passwords. [See other exercises](./readme.md#lab-exercises).

### This exercise requires pre-requisites
Please perform the steps [here](./readme.md#before-you-start) to configure your environment if you haven't done so yet. This exercise follows on from [exercise 7](./lab-exercise7.md), make sure you've cloned this repository and added a Gateway v11.x license to the correct folder

## Key concepts
- [Create Kubernetes Secret](#create-kubernetes-secret)
- [Configure the Gateway](#configure-the-gateway)
- [Update the Gateway](#update-the-gateway)
- [Inspect the Gateway](#inspect-the-gateway)
- [Test your Gateway Deployment](#test-your-gateway-deployment)
e
### Important
- Tail the Layer7 Operator logs in a separate terminal (you may have to set your KUBECONFIG environment variable in the new terminal)
```
kubectl logs -f -l control-plane=controller-manager -c manager
```

### Create Kubernetes Secret
Kubernetes Secrets are stored as base64 encoded strings without any encryption, Graphman accepts encrypted values and decrypts them with either the clusterPassphrase or a user supplied passphrase.

1. Encrypt a value (there may be a warning about the key deriviation which we will ignore for now.)
<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  echo -n "myothersupersecretvalue" | openssl enc -aes-256-cbc -md sha256 -pass pass:7layer -a
  ```
  Output:
  ```
  U2FsdGVkX19+coRzCf5pI1wvM03aDsehAyZBhXQFvZKE+70ZOuzSfZU/xvUSiz+N
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  echo|set /p="myothersupersecretvalue"|"C:\Program Files\Git\usr\bin\openssl" enc -aes-256-cbc -md sha256 -pass pass:7layer -a
  ```
  Output:
  ```
  U2FsdGVkX19+coRzCf5pI1wvM03aDsehAyZBhXQFvZKE+70ZOuzSfZU/xvUSiz+N
  ```
</details>
<br/>

2. Create a simple secret
Note that mysupersecret2 is the encrypted value that we derived in the previous step. This provides encryption for this value at rest in Kubernetes.
```
kubectl create secret generic mysupersecrets --from-literal=mysupersecret1=mysupersecretvalue --from-literal=mysupersecret2=U2FsdGVkX19+coRzCf5pI1wvM03aDsehAyZBhXQFvZKE+70ZOuzSfZU/xvUSiz+N
```
3. Create the exercise 8 resources
This step will create a graphman bundle that exposes a very simple endpoint that returns Gateway Stored Passwords in plaintext and enable access to the GCP Secret Manager via the external secrets operator.
<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  kubectl apply -k ./exercise8-resources
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  kubectl apply -k exercise8-resources
  ```
</details>
<br/>

In a few seconds there will be a secret called database-credentials-gcp created in your namespace. The [external secrets operator](https://external-secrets.io/latest/) creates a local copy of the external secret so that we can use it in Kubernetes. The external secrets operator has integrations for a variety of secret management [providers](https://external-secrets.io/latest/provider/aws-secrets-manager/).
```
kubectl get secret database-credentials-gcp -oyaml
```

### Configure the Gateway
Update [exercise8-resources/gateway.yaml](./exercise8-resources/gateway.yaml).

We need to add two things to this file

- The new bundle we created
```
bundle:
  ...
  - type: graphman
    source: secret
    name: graphman-secret-reader-bundle
```
- External secret references
```
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
```

### Update the Gateway
<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  kubectl apply -f ./exercise8-resources/gateway.yaml
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  kubectl apply -f exercise8-resources\gateway.yaml
  ```
</details>
<br/>

### Inspect the Gateway
- Get pods
```
kubectl get pods
```
output (wait for the ssg pod to hit READY 1/1 before proceeding to the next step)
```
NAME                                                 READY   STATUS    RESTARTS   AGE
layer7-operator-controller-manager-6cb57584d-n9dlz   2/2     Running   0          4d1h
ssg-6c56b6944b-hr497                                 1/1     Running   0          3h48m
```
- Get ssg pod
```
kubectl get pod <pod-name> -oyaml
```
output (annotations)
```
apiVersion: v1
kind: Pod
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
```

- Trigger an update
```
kubectl edit pod <pod-name>
```
Update one of the checksums

### Test your Gateway Deployment
```
kubectl get svc

NAME  TYPE           CLUSTER-IP     EXTERNAL-IP         PORT(S)                         AGE
ssg   LoadBalancer   10.68.4.161    ***34.89.84.69***   8443:31747/TCP,9443:30778/TCP   41m

if your output looks like this that means you don't have an External IP Provisioner in your Kubernetes Cluster. You can still access your Gateway using port-forward.

NAME  TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)                         AGE
ssg   LoadBalancer   10.68.4.126   <PENDING>       8443:31384/TCP,9443:31359/TCP   7m39s
```

If EXTERNAL-IP is stuck in \<PENDING> state
```
kubectl port-forward svc/ssg 9443:9443
```

```
curl https://34.89.84.69:8443/secrets -k

or if you used port-forward

curl https://localhost:9443/secrets -k

```
Response
```
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

##### Sign into Policy Manager
Policy Manager access is less relevant in a deployment like this because we haven't specified an external MySQL database, any changes that we make will only apply to the Gateway that we're connected to and won't survive a restart. It is still useful to check what's been applied. In our configuration we could set the following which would override the default application port configuration.
```
...
listenPorts:
  harden: true
...
```
This configuration removes port 2124, disables 8080 (HTTP) and hardens 8443 and 9443 where 9443 is the only port that allows a Policy Manager connection. The [advanced example](../gateway/advanced-gateway.yaml) shows how this can be customised with your own ports.

```
username: admin
password: 7layer
gateway: 35.189.116.20:9443
```
or if you used port-forward
```
username: admin
password: 7layer
gateway: localhost:9443
```




