
# Lab exercise 5
This exercise help you to Observe Gateway using Open Telemetry Metrics, Traces and Logs. The lab environment has Open Telemetry Operator, [Kibana](https://kibana.brcmlabs.com/) and [Jaeger](https://jaeger.brcmlabs.com/) services pre-installed to monitor the Gateway.

### This exercise requires pre-requisites
Please perform the steps [here](./readme.md#before-you-start) to configure your environment if you haven't done so yet. This exercise follows on from [exercise 1](./lab-exercise1.md), make sure you've cloned this repository and added a Gateway v11.x license to the correct folder

## Key concepts
- [Open Telemetry Collector](#open-telemetry-collector)
- [Create test services](#create-test-services)
- [Configuring the Gateway](#configuring-the-gateway)
- [Update the Gateway](#update-the-gateway)
- [Call Test services](#call-test-services)
- [Moitor Gateway](#moitor-gateway)

### Open Telemetry Collector
1. Update the [collector.yaml](/exercise5-resources/collector.yaml) as below and create it using kubectl. This OTel collector configuration is used to create a OTel Collector as a sidecar to gateway pod.
    1. Name (_***metadata.name***_) - 'workshopuser(n)-eck'
    2. Resource name to uniquely identify the gateway installation (_***spec.config | processors.batch.resource.attributes[layer7gw.name].value***_)- 'workshopuser(n)-ssg'
```
kubectl apply -f ./exercise5-resources/collector.yaml
```
2. Update the instrumentation CRD [instrumentation.ymal](/exercise5-resources/instrumentation.yaml) as below and create it using kubectl. This will inject OTel agent into the Gateway deployment. Also, allows us to set agent configuration.
    1. Service name (_***spec.env[OTEL_SERVICE_NAME].value***_)- 'workshopuser(n)-ssg'
```
kubectl apply -f ./exercise5-resources/instrumentation.yaml
```

### Create test services
To create some test services, we are going to bootstrap the gateway with a bundle.
1. OTel test services.
    1. /test1 - Always success. Calls another service /echotest and returns result from it.
    2. /test2 - Always errors out with a policy error
    3. /test3 - Always errors out with a routing error. Try’s to call an invalid backend service
    4. /test4 - Always Success. No routing.    
    5. /test5 - Takes two query parameters as input and calculate the age (years elapsed). It has some error and needs to be fixed.
        i. dob - Date of birth - default format dd/MM/yyyy
        ii. format (optional) - Specify the format of dob
    6. /echotest - Returns system date and time.

To create bundle as secret, we use Kustomize. This will aslo create a configmap which has a shell script to call these services. Execute to below command to create the granphman bundle secrets

```
kubectl apply -k ./exercise5-resources/
```

### Configuring the Gateway
We can now create/update our Gateway Custom Resource with the bundle and OTel related configuration.
The base CRD can be found [here](/exercise5-resources/gateway.yaml).

1. Add OTel annotation to the gateway container under _***spec.app***_. The OTel operator can observe the containers with these annotations (web-hooks) and inject the OTel agent and/or OTel collector. Update the _***sidecar.opentelemetry.io/inject***_ value with workshop user number.
```
annotations:
    # Collector configuration CRD name.
    sidecar.opentelemetry.io/inject: "workshopuser(n)-eck"
    # Container language type to inject appropriate agent.
    instrumentation.opentelemetry.io/inject-java: "true"
    # Container name to instrument
    instrumentation.opentelemetry.io/container-names: "gateway"
```
2. Update _***spec.app.bundle***_ to point to test service graphman bundles secrets
```
bundle:
  - type: graphman
    source: secret
    name: graphman-otel-test-services
```
3. Disable auto instrumentation of all libraries except jdbc and jvm runtime-metrics. Add below jvm params at _***spec.app.java.extraArgs***_
We can enable or disable each desired instrumentation individually using -Dotel.instrumentation.[name].enabled=true/false
Complete list of supported autinstumnetation library/framework can be found [here](https://opentelemetry.io/docs/instrumentation/java/automatic/agent-config/#suppressing-specific-agent-instrumentation)
```
- -Dotel.instrumentation.common.default-enabled=false
- -Dotel.instrumentation.opentelemetry-api.enabled=true
- -Dotel.instrumentation.runtime-metrics.enabled=true
- -Dotel.instrumentation.jdbc.enabled=true
- -Dotel.instrumentation.jdbc-datasource.enabled=true
```
4. Add Open Telemetry cluster wide properties
Enable service metrics and set metric prefix. For the work shop, let the `otel.metricPrefix` be `l7_`. Also set resource attributes to capture.
Add below cwp's at _***spec.app.cwp.properties***_

```
- name: otel.serviceMetricEnabled
    value: "true"
- name: otel.metricPrefix
    value: l7_
- name: otel.resourceAttributes
    value: k8s.container.name,k8s.pod.name
```

### Update the Gateway
Now that we've configured our Gateway Custom Resource to make Gateway Observable we can now send the updated manifest into Kubernetes. The Layer7 Operator will then reconcile our new desired state with reality.

1. Update the Gateway CR
```
kubectl apply -f ./exercise5-resources/gateway.yaml
```
### Call Test services.
To generate some load, let’s run a job which will call the test services. We will use the config map which we have created above using kustomie (send-api-requests-script) as a volume mount and execute the script.

```
kubectl apply -f ./exercise5-resources/test-services.yaml
```
### Monitor Gateway
1. Login into [Kibana](https://kibana.brcmlabs.com/) and click on 'Analytics' and then click on 'Dashboard'
2. Search for 'Layer7 Gateway Dashboard' and click on the link.
3. Select the Gateway you would to moniter in 'Gateway' dropdown (workshopuser(n)-ssg)
4. You should be able to see the Gateway Service metrics along with jvm mertices on the dashboard.


### Start [Exercise 6](./lab-exercise6.md)
