# Cloud Workshop Labs
This repository contains step-by-step instructions for the Cloud Workshop Labs.

## Before you start
Make sure that you've downloaded your kubeconfig (cloud workshop kubernetes environment access) and configured kubectl to use it.

- Navigate to [this box](https://ent.box.com/s/aeeiqiuhju0pb3xp1dgwbgrhb54j7l0p) link
    - Download the workshopuser(n).kubeconfig that corresponds to the number you were assigned
- Test your kubeconfig
    - Download the Gateway v11.x license [here](https://ent.box.com/s/h4zd4vs2c3vr0n6ze38nqoeyytm0cvfx)
<details>
  <summary>Linux/MacOS</summary>

  ```
  kubectl get all --kubeconfig /path/to/workshopuser(n).kubeconfig
  ```
</details>
<details>
  <summary>Windows</summary>

  ```
  kubectl get all --kubeconfig c:\path\to\workshopuser(n).kubeconfig
  ```
</details>
<br/>

- Update the KUBECONFIG environment variable to point to the kubeconfig file downloaded from Box. This will remove the need to use the --kubeconfig flag for every command.
<details>
  <summary>Linux/MacOS</summary>

  ```
  export KUBECONFIG=~/.kube/workshopuser(n).kubeconfig
  ```
</details>
<details>
  <summary>Windows</summary>

  ```    
  set KUBECONFIG=%USERPROFILE%\.kube\workshopuser(n).kubeconfig
  ```
</details>
<br/>

- Retest your kubeconfig
```
kubectl get all
```

### NOTE: There should be no resources in your namespace at the beginning of the workshop
Testing your kubeconfig should return the following
```
No resources found in workshopuser(n) namespace.
```

# Lab Exercises
- [Exercise 0](./lab-exercise0.md)
  - This exercise explores configuration as code concepts using Graphman.
- [Exercise 1](./lab-exercise1.md)
  - This exercise should familiarize you with the basic concepts of the Layer7 Operator.
- [Exercise 2](./lab-exercise2.md)
  - This exercise introduces initContainers and bundles (restman/graphman)
- [Exercise 3](./lab-exercise3.md)
  - This exercise introduces the repository custom resource
- [Exercise 4](./lab-exercise4.md)
  - This exercise combines the previous examples in more depth
- [Exercise 5](./lab-exercise5.md)
  - This exercise enables Open Telemetry and Service Metrics on Gateway.
- [Exercise 6](./lab-exercise6.md)
  - This exercise introduces custom Gateway Telemetry assertion.
- [Exercise 7](./lab-exercise7.md)
  - This exercise will will trace a Gateway Service using Trace Open Telemetry tracing.
- [Exercise 8](./lab-exercise8.md)
  - This exercise introduces External Secrets
