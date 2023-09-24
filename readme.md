# Cloud Workshop Labs
This repository contains step-by-step instructions for the Cloud Workshop Labs.

## Before you start
Make sure that you've downloaded your kubeconfig (cloud workshop kubernetes environment access) and configured kubectl to use it.

- Navigate to [this box](https://broadcom.ent.box.com/folder/224687821346) link
    - Download the workshopuser(n).kubeconfig that corresponds to the number you were assigned
- Test your kubeconfig
```
kubectl get all --kubeconfig /path/to/workshopuser(n).kubeconfig
```
- Update the KUBECONFIG environment variable
This will remove the need to use the --kubeconfig flag for every command
--------------------------------------------
- Linux/MacOS
```
export KUBECONFIG=/path/to/workshopuser(n).kubeconfig
```
The default location of the kubeconfig file in Linux/MacOS is
```
~/.kube/config
```
- Windows
```    
set KUBECONFIG=/path/to/workshopuser(n).kubeconfig
```
The default location of the kubeconfig file in Windows is
```
%USERPROFILE%\.kube\config
```

- Retest your kubeconfig
```
kubectl get all
```

### NOTE: There should be no resources in your namespace
Testing your kubeconfig should return the following
```
No resources found in workshopuser(n) namespace.
```

# Lab Exercises
- [Exercise 1](./lab-exercise1.md)
  - This exercise should familiarize you with the basic concepts of the Layer7 Operator.
- [Exercise 2](./lab-exercise2.md)
  - This exercise introduces initContainers and bundles (restman/graphman)
- [Exercise 3](./lab-exercise3.md)
  - This exercise introduces the repository custom resource
- [Exercise 4](./lab-exercise4.md)
  - This exercise combines the previous examples in more depth
- [Exercise 5](./lab-exercise5.md)
  - This exercise introduces External Secrets
- [Exercise 6](./lab-exercise6.md)
  - Preview (alpha) - This exercise shows the current features for External Keys