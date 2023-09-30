# Lab exercise 1
This exercise should familiarize you with the basic concepts of the Layer7 Operator and what Operators do in general. [See other exercises](./readme.md#lab-exercises)

### This exercise requires pre-requisites
Please perform the steps [here](./readme.md#before-you-start) to configure your environment if you haven't done so yet.

## Key concepts
- Deploying the Layer7 Operator
- Creating, updating, inspecting and removing a custom resource (Gateway)
- Making sense of the Layer7 Operator logs

1. Clone this repository
```
git clone https://github.com/gazza7205/cloud-workshop-labs
```
```
cd cloud-workshop-labs
```
2. Place a Gateway v11.x license file (license.xml) in [./exercise1-resources/](./exercise1-resources/)

3. Deploy the Layer7 Operator
```
kubectl apply -f ./layer7-operator/rbac.yaml
```
```
kubectl apply -f ./layer7-operator/operator.yaml
```
3. Open up a new terminal to tail the Operator logs
```
kubectl logs -f $(kubectl get pods -oname | grep layer7-operator-controller-manager) manager
```
4. Deploy a Simple Gateway Custom Resource

- Create a secret with your Gateway v11.x license
```
kubectl create secret generic gateway-license --from-file=./exercise1-resources/license.xml
```
- Create a Gateway CR
```
kubectl apply -f - <<EOF
apiVersion: security.brcmlabs.com/v1
kind: Gateway
metadata:
  name: ssg
spec:
  version: "11.0.00_CR1"
  license:
    accept: true
    secretName: gateway-license
  app:
    replicas: 1
    image: docker.io/caapim/gateway:11.0.00_CR1
    management:
      username: admin
      password: 7layer
      cluster:
        password: 7layer
        hostname: gateway.brcmlabs.com
    resources:
      requests:
        memory: 4Gi
        cpu: 2
      limits:
        memory: 4Gi
        cpu: 2
    service:
      # annotations:
      type: LoadBalancer
      ports:
      - name: https
        port: 8443
        targetPort: 8443
        protocol: TCP
      - name: management
        port: 9443
        targetPort: 9443
        protocol: TCP
EOF
```

5. Inspect the Resources the Layer7 Operator created
```
kubectl get all
```

6. Inspect the Gateway Custom Resource

- Show all Gateways
```
kubectl get gateways
```
- Get the Gateway we created
```
kubectl get gateway ssg -oyaml
```
7. Update the Gateway
Change from 1 replica to 2
```
kubectl edit gateway ssg
```
- Confirm the Gateway has been scaled
The Layer Operator Log should indicate the deployment has been updated, this can be confirmed by getting pods
```
kubectl get pods
```
8. Remove the Gateway Custom Resource
```
kubectl delete gateway ssg
```

### Start [Exercise 2](./lab-exercise2.md)