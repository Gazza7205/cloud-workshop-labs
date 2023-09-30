
# Lab exercise 2
This exercise should familiarize you with some of the additional features of the Layer7 Operator and introduce some of the standard Kubernetes concepts and features used throughout this workshop. [See other exercises](./readme.md#lab-exercises).

### This exercise requires pre-requisites
Please perform the steps [here](./readme.md#before-you-start) to configure your environment if you haven't done so yet. This exercise follows on from [exercise 1](./lab-exercise1.md), make sure you've cloned this repository and added a Gateway v11.x license to the correct folder

## Key concepts
- [Creating a Kubernetes Secret for Gateway management](#gateway-management)
- [Creating Kubernetes Secrets with Graphman Bundles](#graphman-bundle)
- [Creating Kubernetes Secrets with Restman Bundles](#restman-bundle)
- [Using Kustomize](#using-kustomize)
- [InitContainers](#initcontainers)
- [Configuring the Gateway](#configuring-the-gateway)
- [Update the Gateway](#update-the-gateway)

### Gateway Management
1. Create a Secret for Gateway Management Credentials
```
kubectl create secret generic gateway-secret --from-literal SSG_ADMIN_USERNAME=admin --from-literal SSG_ADMIN_PASSWORD=7layer
```
2. Inspect the secret
```
kubectl get secret gateway-secret -oyaml
```
3. Using jsonpath to inspect values
```
kubectl get secret gateway-secret -o jsonpath="{.data.SSG_ADMIN_USERNAME}" | base64 -d
kubectl get secret gateway-secret -o jsonpath="{.data.SSG_ADMIN_PASSWORD}" | base64 -d
```
4. Base64 encoding strings for Kubernetes secrets

The base64 encoded value in gateway-secret for SSG_ADMIN_PASSWORD is N2xheWVy (7layer). You might want to edit a Secret in place, new lines should be omitted (and this is not the default).

- Using echo and base64
```
echo 7layer | base64
```
output - note we get some extra characters because echo outputs the trailing newline by default.
```
N2xheWVyCg==
```
- Omitting the new line with echo (man echo ==> -n do not output the trailing newline)
```
echo -n 7layer | base64
```
or
```
printf 7layer | base64
```
output - correct format
```
N2xheWVy
```

### Graphman Bundle
There is a basic graphman bundle that contains a single cluster-wide property [here](./exercise2-resources/cluster-property.json). Following the same process as before we can create a secret with it

1. Create the secret
```
kubectl create secret generic graphman-cluster-property-bundle --from-file=./exercise2-resources/cluster-property.json
```
2. Inspect the secret
Note here that the key is cluster-property.json
```
kubectl get secret graphman-cluster-property-bundle -oyaml
```
output
```
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
When creating secrets from file you can specify the key, this works for kustomize too which we will be using shortly.

This command will fail because the secret already exists.
```
kubectl create secret generic graphman-cluster-property-bundle --from-file=myclusterproperty.json=./exercise2-resources/cluster-property.json
```

### Restman Bundle
There is a basic Restman bundle that contains a single cluster-wide property [here](./exercise2-resources/cluster-property.bundle). Following the same process as before we can create a secret with it

1. Create the secret
```
kubectl create secret generic restman-cluster-property-bundle --from-file=./exercise2-resources/cluster-property.bundle
```
2. Inspect the secret
```
kubectl get secret restman-cluster-property-bundle -oyaml
```
output
```
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

### Using Kustomize
[Kustomize](https://kustomize.io/) introduces a template-free way to customize application configuration that simplifies the use of off-the-shelf applications. Now, built into kubectl as apply -k.

Creating secrets or configmaps by hand can be useful for once off commands, Kustomize is significantly more powerful (we're scratching the surface) and useful for idempotence. In this step we will go through how to create the same secrets with Kustomize.

[kustomization.yaml](./exercise2-resources/kustomization.yaml) is preconfigured to create 3 secrets using the built-in secret generator. 
```
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

1. Create the Secrets using Kustomize
Kustomize expects a folder with a file called kustomization.yaml
```
kubectl apply -k ./exercise2-resources/
```
ouput
```
secret/gateway-secret configured
secret/graphman-cluster-property-bundle configured
secret/restman-cluster-property-bundle configured
```
You may receive this warning which can be ignored
```
Warning: resource secrets/graphman-cluster-property-bundle is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
```

### InitContainers
InitContainers are specialized containers that run before app containers in a Pod. Init containers can contain utilities or setup scripts not present in an app image. They are also useful for copying custom configuration as we will see now.

There is a basic initContainer [here](./exercise2-resources/basic-initcontainer/). If you're familiar with the Gateway Helm Chart, you'll recognize the file/folder structure. You can also check out the examples [here](https://github.com/Layer7-Community/Utilities/tree/main/gateway-init-container-examples) for more details if you're still unsure after this session.

The Gateway initContainer skeleton that we provide works with a shared volume (/opt/docker/custom) and a bootstrap script that moves files from this folder to the correct locations on the Gateway Container.

This is what the initContainer does
```
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
```
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

### Configuring The Gateway
We can now update our Gateway Custom Resource with all of the additional parts that we've configured.

For this we will be configuring [gateway.yaml](./exercise2-resources/gateway.yaml).

1. Gateway Management Secret

uncomment line 25 and remove username/password
```
management:
  secretName: gateway-secret
```
2. Bundles
line 19
```
bundle:
  - type: restman
    source: secret
    name: restman-cluster-property-bundle
  - type: graphman
    source: secret
    name: graphman-cluster-property-bundle
```
3. initContainer
line 20
```
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
```

### Update the Gateway
Now that we've configured our Gateway Custom Resource to use secrets for Gateway management, bundles, initContainers and the bootstrap script we can now send the updated manifest into Kubernetes. The Layer7 Operator will then reconcile our new desired state with reality.

1. Tail the Layer7 Operator logs in a separate terminal
```
kubectl logs -f $(kubectl get pods -oname | grep layer7-operator-controller-manager) manager
```

2. Update the Gateway CR
```
kubectl apply -f ./exercise2-resources/gateway.yaml
```

3. Login to Policy Manager

- To get the Gateway address run the following command
```
kubectl get svc ssg
```
output
```
NAME   TYPE           CLUSTER-IP     ***EXTERNAL-IP***    PORT(S)                         AGE
ssg    LoadBalancer   10.96.14.218   34.168.26.20         8443:32060/TCP,9443:30632/TCP   80s
```

- Open Policy Manager and view the bootstrapped components.
```
User Name: admin
Password: 7layer
Gateway: 34.168.26.20
```

### Start [Exercise 3](./lab-exercise3.md)
