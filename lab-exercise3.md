# Lab Exercise 3

1. [Prerequisites](#1-prerequisites)
1. [Overview](#2-overview)
1. [Gateway Management](#3-gateway-management)
1. [Graphman Bundle](#4-graphman-bundle)
1. [Restman Bundle](#5-restman-bundle)
1. [Using Kustomize](#6-using-kustomize)
1. [InitContainers](#7-initcontainers)
1. [Configure the Gateway](#8-configure-the-gateway)
1. [Update the Gateway](#9-update-the-gateway)
1. [Validate the Update](#10-validate-the-update)


## 1. Prerequisites

Please make sure you've completed the steps [here](./readme.md) and have completed [Lab Exercise 2](./lab-exercise2.md) before beginning this exercise.

## 2. Overview

The Layer7 Operator supports the same deployment options for the Layer7 API Gateway as its Helm chart does, including support for bootstrapping bundles and initContainers. These options offer the Layer7 Operator multiple ways of managing gateways short of using configuration as code in the form of Graphman bundles pulled from git or artifact repository sources of truth, concepts that will be explored in later exercises.

This exercise should familiarize you with some of those options, including bootstrapping bundles and using initContainers, and other related Kubernetes concepts and tools.

## 3. Gateway Management

In this section, we will create and inspect a Kubernetes secret used to manage gateway admin credentials.

First, create the secret:
```
kubectl create secret generic gateway-secret --from-literal SSG_ADMIN_USERNAME=admin --from-literal SSG_ADMIN_PASSWORD=7layer
```

Then, inspect the secret:
```
kubectl get secret gateway-secret -oyaml
```

Try using `jsonpath` to inspect the secret values:
<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  kubectl get secret gateway-secret -o jsonpath="{.data.SSG_ADMIN_USERNAME}" | base64 -d
  ```
  ```
  kubectl get secret gateway-secret -o jsonpath="{.data.SSG_ADMIN_PASSWORD}" | base64 -d
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  kubectl get secret gateway-secret -o jsonpath="{.data.SSG_ADMIN_USERNAME}" > output.txt  && certutil -decode output.txt decoded.txt > nul  && type decoded.txt && del decoded.txt output.txt
  ```
  ```  
  kubectl get secret gateway-secret -o jsonpath="{.data.SSG_ADMIN_PASSWORD}" > output.txt  && certutil -decode output.txt decoded.txt > nul  && type decoded.txt && del decoded.txt output.txt
  ```
</details>
<br/>

If you need to edit a secret value in place, you must provide a base64 encoded value that does not contain newlines. For example, the base64 encoded value in gateway-secret for SSG_ADMIN_PASSWORD is `N2xheWVy` (for `7layer`).
<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  echo -n 7layer | base64
  ```
  Output (correct format without a newline):
  ```
  N2xheWVy
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  It's easiest to use an [online tool](https://www.base64encode.org/) for base64 encoding (and decoding) strings, or a text editor that supports the same.
</details>
<br/>

## 4. Graphman Bundle

There is a basic Graphman bundle that contains a single cluster-wide property here, [./exercise3-resources/cluster-property.json](./exercise3-resources/cluster-property.json). Following the same process as before, we will create a secret that contains this bundle.

First, create the secret:
<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  kubectl create secret generic graphman-cluster-property-bundle --from-file=./exercise3-resources/cluster-property.json
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  kubectl create secret generic graphman-cluster-property-bundle --from-file=exercise3-resources\cluster-property.json
  ```
</details>
<br/>

Then, inspect the secret:
```
kubectl get secret graphman-cluster-property-bundle -oyaml
```

Here is an example of the previous command's output (note that the key is cluster-property.json):
```yaml
apiVersion: v1
data:
  cluster-property.json: ewogICJjbHVzdGVyUHJvcGVydGllcyI6IFsKICAgIHsKICAgICAgIm5hbWUiOiAiYmFja2VuZDEiLAogICAgICAiZGVzY3JpcHRpb24iOiAiYSBjd3AiLAogICAgICAiaGlkZGVuUHJvcGVydHkiOiBmYWxzZSwKICAgICAgInZhbHVlIjogImh0dHBzOi8vbW9jay5icmNtbGFicy5jb20iCiAgICB9CiAgXQp9Cg==
kind: Secret
metadata:
  creationTimestamp: "2023-09-21T05:54:14Z"
  name: graphman-cluster-property-bundle
  namespace: default
  resourceVersion: "1130221"
  uid: 6f567545-9f75-4d38-9533-63c759cc62e8
type: Opaque
```

When creating secrets from file you can specify the key. This also works for [kustomize](https://kustomize.io/) which we will be using shortly.

For example only (these commands will fail because the secret already exists):
<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  kubectl create secret generic graphman-cluster-property-bundle --from-file=myclusterproperty.json=./exercise3-resources/cluster-property.json
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  kubectl create secret generic graphman-cluster-property-bundle --from-file=myclusterproperty.json=exercise3-resources\cluster-property.json
  ```
</details>
<br/>

## 5. Restman Bundle
Though the Layer7 Operator is designed to primarily work with Graphman, Restman bundles can also be boostrapped to container gateways managed by the Layer7 Opertor using secrets or other mechanisms.

There is a basic Restman bundle that contains a single cluster-wide property here, [./exercise3-resources/cluster-property.bundle](./exercise3-resources/cluster-property.bundle). Following the same process as before, we will create a secret that contains this bundle.

First, create the secret:
<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  kubectl create secret generic restman-cluster-property-bundle --from-file=./exercise3-resources/cluster-property.bundle
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  kubectl create secret generic restman-cluster-property-bundle --from-file=exercise3-resources\cluster-property.bundle
  ```
</details>
<br/>

Then, inspect the secret:
```
kubectl get secret restman-cluster-property-bundle -oyaml
```

Here is an example of the previous command's output:
```yaml
apiVersion: v1
data:
  cluster-property.bundle: PGw3OkJ1bmRsZSB4bWxuczpsNz0iaHR0cDovL25zLmw3dGVjaC5jb20vMjAxMC8wNC9nYXRld2F5LW1hbmFnZW1lbnQiPgogICAgPGw3OlJlZmVyZW5jZXM+CiAgICAgICAgPGw3Okl0ZW0+CiAgICAgICAgICAgIDxsNzpOYW1lPmJhY2tlbmQyPC9sNzpOYW1lPgogICAgICAgICAgICA8bDc6SWQ+aGM1N2NjMjYyMWI5MmEyMzMxZjYzY2MwZjBjMTQwMmM8L2w3OklkPgogICAgICAgICAgICA8bDc6VHlwZT5DTFVTVEVSX1BST1BFUlRZPC9sNzpUeXBlPgogICAgICAgICAgICA8bDc6UmVzb3VyY2U+CiAgICAgICAgICAgICAgICA8bDc6Q2x1c3RlclByb3BlcnR5IGlkPSJmYjU3Y2MyNjIxYjkyYTUzMzFmNjNjYzBmMGMzNDAxZCI+CiAgICAgICAgICAgICAgICAgICAgPGw3Ok5hbWU+YmFja2VuZDI8L2w3Ok5hbWU+CiAgICAgICAgICAgICAgICAgICAgPGw3OlZhbHVlPmh0dHBzOi8vbW9jazEuYnJjbWxhYnMuY29tPC9sNzpWYWx1ZT4KICAgICAgICAgICAgICAgIDwvbDc6Q2x1c3RlclByb3BlcnR5PgogICAgICAgICAgICA8L2w3OlJlc291cmNlPgogICAgICAgIDwvbDc6SXRlbT4KICAgIDwvbDc6UmVmZXJlbmNlcz4KICAgIDxsNzpNYXBwaW5ncz4KICAgICAgICA8bDc6TWFwcGluZyBhY3Rpb249Ik5ld09yVXBkYXRlIiBzcmNJZD0iZmI1N2NjMjYyMWI5MmE1MzMxZjYzY2MwZjBjMzQwMWQiIHR5cGU9IkNMVVNURVJfUFJPUEVSVFkiPgogICAgICAgICAgICA8bDc6UHJvcGVydGllcz4KICAgICAgICAgICAgICAgIDxsNzpQcm9wZXJ0eSBrZXk9Ik1hcEJ5Ij4KICAgICAgICAgICAgICAgICAgICA8bDc6U3RyaW5nVmFsdWU+bmFtZTwvbDc6U3RyaW5nVmFsdWU+CiAgICAgICAgICAgICAgICA8L2w3OlByb3BlcnR5PgogICAgICAgICAgICAgICAgPGw3OlByb3BlcnR5IGtleT0iTWFwVG8iPgogICAgICAgICAgICAgICAgICAgIDxsNzpTdHJpbmdWYWx1ZT5iYWNrZW5kMjwvbDc6U3RyaW5nVmFsdWU+CiAgICAgICAgICAgICAgICA8L2w3OlByb3BlcnR5PgogICAgICAgICAgICA8L2w3OlByb3BlcnRpZXM+CiAgICAgICAgPC9sNzpNYXBwaW5nPgogICAgPC9sNzpNYXBwaW5ncz4KPC9sNzpCdW5kbGU+
kind: Secret
metadata:
  creationTimestamp: "2023-09-21T06:53:39Z"
  name: restman-cluster-property-bundle
  namespace: default
  resourceVersion: "1136618"
  uid: 7c9ae499-b0af-42f5-a77e-5090b9c073c1
type: Opaque
```

## 6. Using Kustomize
[Kustomize](https://kustomize.io/) introduces a template-free way to customize application configuration that simplifies the use of off-the-shelf applications. It is now built into kubectl as `apply -k`.

Creating secrets or configmaps by hand can be useful for one off commands, but Kustomize is significantly more powerful (we're scratching the surface) and useful for idempotence. In this step we will go through how to create the same secrets with Kustomize.

[./exercise3-resources/kustomization.yaml](./exercise3-resources/kustomization.yaml) is preconfigured to create 3 secrets using the built-in secret generator. 
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
generatorOptions:
 disableNameSuffixHash: true
secretGenerator:
- name: gateway-secret
  env: ./secret.env
- name: graphman-cluster-property-bundle
  files:
    - ./cluster-property.json
- name: restman-cluster-property-bundle
  files:
    - ./cluster-property.bundle
```

Create the secrets using Kustomize. Kustomize expects a folder with a file called kustomization.yaml:
```
kubectl apply -k exercise3-resources
```

Because we had previously created these secrets, the output of the previous command may have warnings like these (that you can ignore):
```
Warning: resource secrets/gateway-secret is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
secret/gateway-secret configured
Warning: resource secrets/graphman-cluster-property-bundle is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
secret/graphman-cluster-property-bundle configured
Warning: resource secrets/restman-cluster-property-bundle is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
secret/restman-cluster-property-bundle configured
```

If you run the same command again, you will not see those warnings. For example:
```
secret/gateway-secret unchanged
secret/graphman-cluster-property-bundle configured
secret/restman-cluster-property-bundle configured
```

## 7. InitContainers
InitContainers are special containers that run before application containers in a pod. InitContainers can contain utilities or setup scripts not present in the application image. They can also share file system volumes with the application container making them useful for copying custom configuration as we will see now.

There is a basic initContainer here, [./exercise2-resources/basic-initcontainer](./exercise2-resources/basic-initcontainer/). If you're familiar with the Gateway Helm Chart, you'll recognize the file/folder structure. There are additional examples [here](https://github.com/Layer7-Community/Utilities/tree/main/gateway-init-container-examples) if you want to learn more about using initContainers with Layer7 API Gateways.

The basic initContainer that we provide works with a shared volume (/opt/docker/custom) and a bootstrap script that moves files from this folder to the correct locations on the gateway container during startup.

This is what the initContainer does:
```bash
run_custom_scripts() {
        scripts=$(find "./scripts" -type f 2>/dev/null)
        for script in $scripts; do
                filename=$(basename "$script")
                ext=${filename##*.}
                if [[ ${ext} == sh ]]; then
                        /bin/bash $script
                elif [[ ${ext} == "py" ]] && [[ "${filename}" == *"preboot_"* ]]; then
                        python $script
                fi
                if [ $? -ne 0 ]; then
                        echo "Failed executing the script: ${i}"
                fi
        done
        unset i
}


copyFiles() {
        cp -r config/* /opt/docker/custom/
}
#run_custom_scripts
copyFiles
```
This is what the bootstrap script on the Gateway does
```bash
#!/bin/bash
BASE_CONFIG_DIR="/opt/docker/custom"
GRAPHMAN_CONFIG_DIR="/opt/docker/graphman"
BUNDLE_DIR="$BASE_CONFIG_DIR/bundle"
CUSTOM_ASSERTIONS_DIR="$BASE_CONFIG_DIR/custom-assertions"
MODULAR_ASSERTIONS_DIR="$BASE_CONFIG_DIR/modular-assertions"
EXTERNAL_LIBRARIES_DIR="$BASE_CONFIG_DIR/external-libraries"
CUSTOM_PROPERTIES_DIR="$BASE_CONFIG_DIR/custom-properties"
CUSTOM_HEALTHCHECK_SCRIPTS_DIR="$BASE_CONFIG_DIR/health-checks"
CUSTOM_SHELL_SCRIPTS_DIR="$BASE_CONFIG_DIR/scripts"

BASE_TARGET_DIR="/opt/SecureSpan/Gateway"
GRAPHMAN_BOOTSTRAP_DIR="$BASE_TARGET_DIR/node/default/etc/bootstrap/bundle"
TARGET_CUSTOM_ASSERTIONS_DIR="$BASE_TARGET_DIR/runtime/modules/lib"
TARGET_MODULAR_ASSERTIONS_DIR="$BASE_TARGET_DIR/runtime/modules/assertions"
TARGET_EXTERNAL_LIBRARIES_DIR="$BASE_TARGET_DIR/runtime/lib/ext"
TARGET_BUNDLE_DIR="$BASE_TARGET_DIR/node/default/etc/bootstrap/bundle"
TARGET_CUSTOM_PROPERTIES_DIR="$BASE_TARGET_DIR/node/default/etc/conf"
TARGET_HEALTHCHECK_DIR="/opt/docker/rc.d/diagnostic/health_check"

error() {
    echo "ERROR - ${1}" 1>&2
    exit 1
}
function cleanup() {
    echo "***************************************************************************"
    echo "removing $BASE_CONFIG_DIR"
    echo "***************************************************************************"
    rm -rf $BASE_CONFIG_DIR/*
}

function copy() {
    TYPE=$1
    EXT=$2
    SOURCE_DIR=$3
    TARGET_DIR=$4
    echo "***************************************************************************"
    echo "scanning for $TYPE in $SOURCE_DIR"
    echo "***************************************************************************"
    FILES=$(find $3 -type f -name '*'$2 2>/dev/null)
    for file in $FILES; do
        name=$(basename "$file")
        cp $file $4/$name
        echo -e "$name written to $4/$name"
    done
}

function gunzip() {
    TYPE=$1
    EXT=$2
    SOURCE_DIR=$3
    echo "***************************************************************************"
    echo "scanning for $TYPE in $SOURCE_DIR"
    echo "***************************************************************************"
    FILES=$(find $3 -type f -name '*'$2 2>/dev/null)
    for file in $FILES; do
        fullname=$(basename "$file")
        name="${fullname%.*}"
        cat $file | gzip -d > $GRAPHMAN_BOOTSTRAP_DIR/$name".json"
        echo -e "$name decompressed"
    done
}

function run() {
    TYPE=$1
    EXT=$2
    SOURCE_DIR=$3
    echo "***************************************************************************"
    echo "scanning for $TYPE in $SOURCE_DIR"
    echo "***************************************************************************"
    FILES=$(find $3 -type f -name '*'$2 2>/dev/null)
    for file in $FILES; do
        name=$(basename "$file")
        echo -e "running $name"
        /bin/bash $file
        if [ $? -ne 0 ]; then
            echo "Failed executing the script: $file"
            exit 1
        fi
    done
}

gunzip "graphman bundles" ".gz" $GRAPHMAN_CONFIG_DIR
copy "bundles" ".bundle" $BUNDLE_DIR $TARGET_BUNDLE_DIR
copy "custom assertions" ".jar" $CUSTOM_ASSERTIONS_DIR $TARGET_CUSTOM_ASSERTIONS_DIR
copy "modular assertions" ".aar" $MODULAR_ASSERTIONS_DIR $TARGET_MODULAR_ASSERTIONS_DIR
copy "external libraries" ".jar" $EXTERNAL_LIBRARIES_DIR $TARGET_EXTERNAL_LIBRARIES_DIR
copy "custom properties" ".properties" $CUSTOM_PROPERTIES_DIR $TARGET_CUSTOM_PROPERTIES_DIR
copy "custom health checks" ".sh" $CUSTOM_HEALTHCHECK_SCRIPTS_DIR $TARGET_HEALTHCHECK_DIR
run "custom shell scripts" ".sh" $CUSTOM_SHELL_SCRIPTS_DIR
```

## 8. Configure The Gateway
We can now update our Gateway Custom Resource with all of the additional parts that we've configured.

For this we will be configuring this file, [`./exercise3-resources/gateway.yaml`](./exercise3-resources/gateway.yaml).

Additional documentation for Gateway custom resources can be found [here](https://github.com/CAAPIM/layer7-operator/wiki/Gateway-Custom-Resource).

First, reference the gateway secret that we created by uncommenting `secretName` (~ line 32) and deleting the following `username` and `password` lines. For example:

```yaml
...
    management:
      secretName: gateway-secret
      service:
...
```

Next, enable the bootstrap script (~ line 27) and add an initContainer. For example:

```yaml
...
    bundle: []
    bootstrap:
      script:
        enabled: true
    initContainers:
    - name: workshop-init
      image: harbor.sutraone.com/mock/workshop-init:1.0.0
      imagePullPolicy: IfNotPresent
      volumeMounts:
      - name: config-directory
        mountPath: /opt/docker/custom
    management:
...
```

Finally, references the bundles that we created by replacing the bundle array (~ line 26) as follows:

```yaml
...
        cpu:
    bundle:
    - type: restman
      source: secret
      name: restman-cluster-property-bundle
    - type: graphman
      source: secret
      name: graphman-cluster-property-bundle
    bootstrap:
...
```

## 9. Update The Gateway
We can now apply the Gateway custom cesource manifest in Kubernetes. The Layer7 Operator will then reconcile actual state with our new desired state.

First, if you're not still tailing the Layer7 Operator logs from the previous lab exercise, then start doing that now in a separate terminal (you may have to set your KUBECONFIG environment variable in the new terminal):

```
kubectl logs -f -l control-plane=controller-manager -c manager
```

Next, apply the updated manifest:
<details>
  <summary><b>Linux/MacOS</b></summary>

  ```
  kubectl apply -f ./exercise3-resources/gateway.yaml
  ```
</details>
<details>
  <summary><b>Windows</b></summary>

  ```
  kubectl apply -f exercise3-resources\gateway.yaml
  ```
</details>
<br/>

## 10. Validate the Update
Now test the update by calling an API and connecting with Policy Manager.

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
curl -k https://<your-external-ip>:8443/helloworld
```

The API should respond as follows:
```
Hello World!
```

Finally, connect to your gateway with Policy Manager to view the bootstrapped bundles:

```
User Name: admin
Password: 7layer
Gateway: <your-external-ip>
```

# Start [Lab Exercise 4](./lab-exercise4.md)
