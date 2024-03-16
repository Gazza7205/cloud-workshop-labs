# Cloud Workshop Labs
This repository contains step-by-step instructions for the Cloud Workshop Labs.

## 1. Important
Use a browser (or markdown preview pane) to view this lab content during the workshop. Do not try to use the raw markdown content directly during the workshop.

## 2. Prerequisites
- [kubectl (v1.27+)](https://kubernetes.io/docs/tasks/tools/)
- [GitHub Account](https://github.com/signup)
- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) or [GitHub Desktop](https://docs.github.com/en/desktop/installing-and-authenticating-to-github-desktop/installing-github-desktop)
- [Temurin OpenJDK 11](https://adoptium.net/temurin/releases/?version=11) (for Mac users; 11 or later depending on version of Layer7 Policy Manager deployed at the time of the workshop)
- [Layer7 Policy Manager 11.0 CR1](https://support.broadcom.com/group/ecx/productfiles?sellable=APIENT990&release=11.0&os=MULTI-PLATFORM&servicePk=0000&language=EN) (or later depending on actual gateway version deployed at the time of the workshop)
- [Node.js (v16+)](https://nodejs.org/en/download)

## 3. Share your GitHub ID
A private GitHub repository is used for sharing a temporary license and environment related information required by this workshop. You must share your GitHub ID with the workshop coordinator to be given access to the private repository.

## 4. Download a Temporary License
A temporary license has been provided for this workshop. Download the [license](https://github.com/CAAPIM/cloud-workshop-labs-environment/blob/main/cloud-workshop/license.xml) from the private repository.

## 5. Connect to Kubernetes
For this workshop, you will be assigned a user number and a corresponding namespace in a shared Kubernetes cluster. Download the [kubeconfig file for your user number](https://github.com/CAAPIM/cloud-workshop-labs-environment/tree/main/cloud-workshop/attendees) (e.g. `workshopuser(n).kubeconfig`) from the private repository.

Update and execute the following command with the path to your kubeconfig file, and test your connection to the Kubernetes cluster:

<details>
  <summary>Linux/MacOS</summary>

  ```
  kubectl get all --kubeconfig /path/to/workshopuser(n).kubeconfig
  ```

  Expected response at the beginning of the workshop:
  ```
  No resources found in workshopuser(n) namespace.
  ```
</details>
<details>
  <summary>Windows</summary>

  ```
  kubectl get all --kubeconfig c:\path\to\workshopuser(n).kubeconfig
  ```

  Expected response at the beginning of the workshop:
  ```
  No resources found in workshopuser(n) namespace.
  ```
</details>
<br/>

To avoid providing the `--kubeconfig` argument with every `kubectl` command, update and execute the following command with the path to your kubeconfig file to set the KUBECONFIG environment variable in your current shell. _**Note: This command will only set the environment variable in your current shell. You will need to repeat this command in new shells you open later, or use a more permanent option for setting environment variables in whatever operating system you are working with.**_

<details>
  <summary>Linux/MacOS</summary>

  ```
  export KUBECONFIG=/path/to/workshopuser(n).kubeconfig
  ```
</details>
<details>
  <summary>Windows</summary>

  ```    
  set KUBECONFIG=c:\path\to\workshopuser(n).kubeconfig
  ```
</details>
<br/>

Test your configuration again:
```
kubectl get all
```
Expected response at the beginning of the workshop:
```
No resources found in workshopuser(n) namespace.
```

# Lab Exercises
- [Exercise 1](./lab-exercise1.md)
  - This exercise explores configuration as code concepts using Graphman.
- [Exercise 2](./lab-exercise2.md)
  - This exercise should familiarize you with the basic concepts of the Layer7 Operator.
- [Exercise 3](./lab-exercise3.md)
  - This exercise introduces initContainers and bundles (restman/graphman)
- [Exercise 4](./lab-exercise4.md)
  - This exercise introduces the repository custom resource
- [Exercise 5](./lab-exercise5.md)
  - This exercise combines the previous examples in more depth
- [Exercise 6](./lab-exercise6.md)
  - This exercise enables Open Telemetry and Service Metrics on Gateway.
- [Exercise 7](./lab-exercise7.md)
  - This exercise introduces custom Gateway Telemetry assertion.
- [Exercise 8](./lab-exercise8.md)
  - This exercise will will trace a Gateway Service using Trace Open Telemetry tracing.
- [Exercise 9](./lab-exercise9.md)
  - This exercise introduces External Secrets
