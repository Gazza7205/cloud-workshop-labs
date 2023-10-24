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
<details>
  <summary style="color:darkgreen;font-weight:bold">Linux/MacOS</summary>

  ```
  kubectl apply -f ./layer7-operator/rbac.yaml
  ```
  ```
  kubectl apply -f ./layer7-operator/operator.yaml
  ```
</details>
<details>
  <summary style="color:darkgreen;font-weight:bold">Windows</summary>

  ```
  kubectl apply -f layer7-operator\rbac.yaml
  ```
  ```  
  kubectl apply -f layer7-operator\operator.yaml
  ```
</details>
<br/>

3. Open up a new terminal to tail the Operator logs (you may have to set your KUBECONFIG environment variable in the new terminalkube)
```
kubectl logs -f -l control-plane=controller-manager -c manager
```
4. Deploy a Simple Gateway Custom Resource

- Create a secret with your Gateway v11.x license
<details>
  <summary style="color:darkgreen;font-weight:bold">Linux/MacOS</summary>

  ```
  kubectl create secret generic gateway-license --from-file=./exercise1-resources/license.xml
  ```
</details>
<details>
  <summary style="color:darkgreen;font-weight:bold">Windows</summary>

  ```
  kubectl create secret generic gateway-license --from-file=exercise1-resources\license.xml
  ```
</details>
<br/>

- Create a Gateway CR
<details>
  <summary style="color:darkgreen;font-weight:bold">Linux/MacOS</summary>

  ```
  kubectl apply -f ./exercise1-resources/gateway.yaml
  ```
</details>
<details>
  <summary style="color:darkgreen;font-weight:bold">Windows</summary>

  ```
  kubectl apply -f exercise1-resources\gateway.yaml
  ```
</details>
<br/>

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