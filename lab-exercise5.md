# Lab exercise 5
This exercise introduces how to use external kubernetes secrets as Gateway Stored Passwords. [See other exercises](./readme.md#lab-exercises).

### This exercise requires pre-requisites
Please perform the steps [here](./readme.md#before-you-start) to configure your environment if you haven't done so yet. This exercise follows on from [exercise 4](./lab-exercise4.md), make sure you've cloned this repository and added a Gateway v11.x license to the correct folder

You will have an updated gateway at this point, copy your gateway.yaml into [./exercise5-resources](./exercise5-resources/). Make sure that replicas is equal to 1 before applying.

## Key concepts
- [Create Kubernetes Secret](#create-kubernetes-secret)
- [Configure Gateway](#configure-repository-references)
- [Update the Gateway](#update-the-gateway)
- [Inspect the Gateway](#inspect-the-gateway)
- [Test your Gateway Deployment](#test-your-gateway-deployment)

### Create Kubernetes Secret
Kubernetes Secrets are stored as base64 encoded strings without any encryption, Graphman accepts encrypted values and decrypts them with either the clusterPassphrase or a user supplied passphrase.

1. Encrypt a value (there may be a warning about the key deriviation which we will ignore for now.)
```
echo -n "myothersupersecretvalue" | openssl enc -aes-256-cbc -md sha256 -pass pass:7layer -a
```
output
```
U2FsdGVkX19+coRzCf5pI1wvM03aDsehAyZBhXQFvZKE+70ZOuzSfZU/xvUSiz+N
```

2. Create a simple secret
Note that mysupersecret2 is the encrypted value that we derived in the previous step. This provides encryption for this value at rest in Kubernetes.
```
kubectl create secret generic mysupersecrets --from-literal=mysupersecret1=mysupersecretvalue --from-literal=mysupersecret2=U2FsdGVkX19+coRzCf5pI1wvM03aDsehAyZBhXQFvZKE+70ZOuzSfZU/xvUSiz+N
```
3. Create the exercise 5 resources
This step will create a graphman bundle that exposes a very simple endpoint that returns Gateway Stored Passwords in plaintext and enable access to the GCP Secret Manager via the external secrets operator.
```
kubectl apply -k ./exercise5-resources
```
In a few seconds there will be a secret called database-credentials-gcp created in your namespace. The [external secrets operator](https://external-secrets.io/latest/) creates a local copy of the external secret so that we can use it in Kubernetes. The external secrets operator has integrations for a variety of secret management [providers](https://external-secrets.io/latest/provider/aws-secrets-manager/).
```
kubectl get secret database-credentials-gcp -oyaml
```

3. Update [gateway.yaml](./exercise5-resources/gateway.yaml). You may be using a gateway definition from a previous exercise, please ensure that replicas is set to 1.
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
  - name: mysupersecrets
    enabled: true
    description: top secret
  - name: private-key-secret
    enabled: true
    description: a private key
```

4. Configure the external secrets operator

output
```
NAME                    AGE
l7-gw-myapis            67s
l7-gw-myframework       67s
l7-gw-mysubscriptions   67s
```

### Configure Repository References
Here we will configure repository references for our Gateway custom resource. Repository references are used by the Gateway controller to reconcile the resulting graphman bundles from our repositories to Gateways. This is tracked using annotations that are applied to each gateway pod (in ephemeral mode) or deployment (when there is a MySQL database configured).

- Open [gateway.yaml](./exercise4-resources/gateway.yaml) and configure repository references on line 30
```
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
```
Let's take a closer look at some of the fields
#### type - static|dynamic
- static
    - requires a gateway restart
    - applied via a dynamic initContainer
    - useful for infrastructure that is less frequent to change
    - using tags is recommended!!
- dynamic
    - applied automatically with no restarts required
    - useful for frequent changes
    - includes support for singleton configurations
    - zero downtime
#### encryption
Certain entities (like stored passwords) can be encrypted for secure storage. The encryption configuration here allows us to provide a decryption key for the Graphman service. We will create the [graphman-encryption-secret](./exercise4-resources/graphman-encryption-secret.env) shortly.

- Create the [graphman-encryption-secret](./exercise4-resources/graphman-encryption-secret.env)
```
kubectl create secret generic graphman-encryption-secret --from-env-file=./exercise4-resources/graphman-encryption-secret.env
```

### Singleton Configs
You will see a config option called singletonExtraction on line 29 in [gateway.yaml](./exercise4-resources/gateway.yaml). Singletons in this context are Gateway Scheduled Tasks or JMS listeners that should only run on one Gateway. It's easy to track this when there's an external MySQL database. In ephemeral mode, gateways have no awareness of additional cluster nodes or deployments.

Singleton Extraction aims to mitigate this by designating one gateway pods as a leader and only applying scheduled tasks and jms listeners to that pod. This comes with a current limitation to dynamic repository references only. 

### Update the Gateway
Using our newly configured [gateway.yaml](./exercise4-resources/gateway.yaml) we will now update our gateway.

- Make sure that you still have a separate terminal with the Layer7 Operator logs
```
kubectl logs -f $(kubectl get pods -oname | grep layer7-operator-controller-manager) manager
```
- Update the Gateway
```
kubectl apply -f ./exercise4-resources/gateway.yaml
```
This will trigger an update to your Gateway deployment with the addition of the static repository.

### Inspect the Gateway
Let's take a look at the Gateway CR
```
kubectl get gateway ssg -oyaml
```
output (status)
```
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

### Inspect the Gateway Deployment
```
kubectl describe deployment ssg
```
output (initContainers)
```
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
```
#### Inspect the Gateway Pod
- Get pods
```
kubectl get pods
```
output (wait for the ssg pod to hit READY 1/1 before proceeding to the next step)
```
NAME                                                  READY   STATUS    RESTARTS   AGE
layer7-operator-controller-manager-77bb65f7fb-87gv4   2/2     Running   0          4d16h
ssg-74bc56d55c-cgctb                                  1/1     Running   0          6m38s
```
- Get ssg pod
```
kubectl get pod ssg-74bc56d55c-cgctb -oyaml
```
output (annotations)
```
apiVersion: v1
kind: Pod
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
```

- Trigger an update
```
kubectl edit pod ssg-74bc56d55c-cgctb
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
curl https://34.89.84.69:8443/api1 -H "client-id: D63FA04C8447" -k

or if you used port-forward

curl https://localhost:9443/api1 -H "client-id: D63FA04C8447" -k

```
Response
```
{
  "client" : "D63FA04C8447",
  "plan" : "plan_a",
  "service" : "hello api 1",
  "myDemoConfigVal" : "Deep Inside Config"
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

### Start [Exercise 5](./lab-exercise5.md)


