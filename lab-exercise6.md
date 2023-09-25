
# Lab exercise 6
This exercise help you to Observe Gateway using OpenTelemetry Metrics, Traces and Logs. The lab environment is has Open Telemetry Operator, [Kibana](https://kibana.brcmlabs.com/) and [Jaeger](https://jaeger.brcmlabs.com/) services pre-installed to moniter the Gateway.

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

### Open Telemetry Collector
1. Update the [collector.yaml](/exercise6-resources/collector.yaml) as below and create it using kubectl. This OTel collector configureation is used to create a OTel Collecor as a sidecar when the gateway comes up.
    a. Name - 'workshopuser(n)-eck'
    b. Resource name to uniquely identtify the gateway installation - 'workshopuser(n)-ssg'
```
kubectl apply -f ./exercise6-resources/collector.yaml
```
2. Update the instrumentation CRD [instrumentation.ymal](/exercise6-resources/instrumentation.yaml) create it using kubectl. This will inject OTel agent into the Gateway deploymnet. Also, alows us to set agent configuration.
    a. Service name - 'workshopuser(n)-ssg'
```
kubectl apply -f ./exercise6-resources/instrumentation.yaml
```

### Create test servics
To create some test services, we are going to bootstap the gateway with some bundles.
1. OTel test services. All services have 'export_metric_variables' policy embeded in them.
    a. /test1 - Allways success. Calls another service /echotest and returns result from it.
    b. /test2 - Allways errors out with a policy error
    c. /test3 - Allways errors out with a routing error. Trys to call an invalid backend service
    d. /test4 - Allways Scuccess. No routing to policy error.    
    e. /test5 - Takes two query parameters as input and calulate the age (years elapsed). It has some error and needs to be fixed.
        i. dob - Date of birth - default format dd/MM/yyyy
        ii. format (optional) - Specify the format of dob
    f. /echotest - Returns system date and time.
2. export_metric_variables - This is a template policy which does a context variables export of
    a. Service name
    b. Service OID
    c. Service URL
    d. Org Id if present in query param. Set to 'NONE' otherwise.
3. Message completed policy having Telemetry assertion.

```
kubectl apply -k ./exercise6-resources/
```

### Configuring The Gateway
We can now create/update our Gateway Custom Resource with the bundles and OTel related configuration.

1. Add OTel annotation to the gateway container. The OTel operator can observe the containers with these annotations (web-hooks) and inject the OTel agent and/or OTel collector. Update the CRD name accordingly.
```
annotations:
    # Collector configuration CRD name.
    sidecar.opentelemetry.io/inject: "workshopuser(n)-eck"
    # Container language type to inject appropriate agent.
    instrumentation.opentelemetry.io/inject-java: "true"
    # Container name to instrument
    instrumentation.opentelemetry.io/container-names: "gateway"
```
2. Test service bundles.
```
bundle:
    - type: graphman
    source: secret
    name: graphman-otel-test-services
    - type: graphman
    source: secret
    name: graphman-otel-message-complete
```
3. Disable auto instrumentation of all libraries except c3p0 and runtime-metrics
```
- -Dotel.instrumentation.common.default-enabled=false
- -Dotel.instrumentation.runtime-metrics.enabled=true
- -Dotel.instrumentation.c3p0.enabled=true
```
For this we will be configuring [gateway.yaml](./exercise2-resources/gateway.yaml).
2. Update the Gateway CR
```
kubectl apply -f ./exercise2-resources/gateway.yaml
```

### Update the Gateway
Now that we've configured our Gateway Custom Resource to make Gateway Observable we can now send the updated manifest into Kubernetes. The Layer7 Operator will then reconcile our new desired state with reality.

1. Update the Gateway CR
```
kubectl apply -f ./exercise6-resources/gateway.yaml
```
### Test services.
To generate some load, lets start a container which will do curl calls 



### Start [Exercise 7](./lab-exercise7.md)