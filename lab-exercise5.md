
# Lab exercise 5
In this exercise you will Observe your Gateway using Open Telemetry Metrics, Traces and Logs. The lab environment has the Open Telemetry Operator, [Kibana](https://kibana.brcmlabs.com/) and [Jaeger](https://jaeger.brcmlabs.com/) services pre-installed to monitor the Gateway. [See other exercises](./readme.md#lab-exercises).

### This exercise requires pre-requisites
Please perform the steps [here](./readme.md#before-you-start) to configure your environment if you haven't done so yet. This exercise follows on from [exercise 4](./lab-exercise4.md) and is a pre-requisite for this.

## Key concepts
- [Open Telemetry Collector](#open-telemetry-collector)
- [Create test services](#create-test-services)
- [Configuring the Gateway](#configuring-the-gateway)
- [Update the Gateway](#update-the-gateway)
- [Call Test services](#call-test-services)
- [Monitor Gateway](#monitor-gateway)

### Open Telemetry Collector
1. Create OTel collector custom resource as below using kubectl. This OTel collector configuration is used to create a OTel Collector as a sidecar to gateway pod. Make sure you update the yaml as below
    1. Name (_***metadata.name***_) - 'workshopuser(n)-eck'
    2. Resource name - To uniquely identify the gateway installation (_***spec.config | processors.batch.resource.attributes[layer7gw.name].value***_)- 'workshopuser(n)-ssg'
```yaml
kubectl apply -f - <<EOF
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: workshopuser(n)-eck
spec:
  image: otel/opentelemetry-collector-contrib:0.77.0
  mode: sidecar
  config: |
    receivers:
      otlp:
        protocols:
          grpc:
          http:
    processors:
      batch:
      resource:
        attributes:
        - key: layer7gw.name
          value: "workshopuser(n)-ssg"
          action: upsert
    exporters:
      logging:
        loglevel: warn 
      otlp/elastic:
        endpoint: apm-server-apm-http.elastic.svc.cluster.local:8200
        tls:
          insecure_skip_verify: true
        headers:
          Authorization: "Bearer 4c3K0d9UP05C6nicW5Wl8rC7"
      jaeger:
        endpoint: jaeger-cloud-workshop-collector-headless.observability.svc.cluster.local:14250
        tls:
          insecure: true
    service:
      telemetry:
        logs:
          level: "debug"
        metrics:
          address: "0.0.0.0:8888"
      pipelines:
        traces:
          receivers: [otlp]
          processors: [resource,batch]
          exporters: [jaeger,otlp/elastic]
        metrics:
          receivers: [otlp]
          processors: [resource,batch]
          exporters: [otlp/elastic]
        logs: 
          receivers: [otlp]
          exporters: [otlp/elastic]
EOF
```

2. Create OTel instrumentation CRD given below using kubectl. This will inject OTel agent into the Gateway deployment. Also, allows us to set agent configuration. Update the ***workshopuser(n)-ssg** below accordingly.

```yaml
kubectl apply -f - <<EOF
apiVersion: opentelemetry.io/v1alpha1
kind: Instrumentation
metadata:
  name: otel-instrumentation
spec:
  env:
    - name: OTEL_SERVICE_NAME
      value: workshopuser(n)-ssg
    - name: OTEL_METRICS_EXPORTER
      value: otlp
    - name: OTEL_TRACES_EXPORTER
      value: otlp
    - name: OTEL_RESOURCE_ATTRIBUTES
      value: service.version=11.0.00,deployment.environment=development
  exporter:
    endpoint: http://localhost:4317
  propagators:
    - tracecontext
    - baggage
    - b3
EOF
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

Create bundle as secret.
```
kubectl create secret generic graphman-otel-test-services  --from-file=./exercise5-resources/otel_test_services.json 
```

### Configuring the Gateway
We can now create/update our Gateway Custom Resource with the bundle and OTel related configuration.
The base CRD can be found [here](/exercise5-resources/gateway.yaml).

1. Add OTel annotation to the gateway container under _***spec.app***_. The OTel operator can observe the containers with these annotations (web-hooks) and inject the OTel agent and/or OTel collector. </br> __*Uncomment lines 11 to 14 and update the value of sidecar.opentelemetry.io/inject with workshop user number.*__
```yaml
annotations:
    # Collector configuration CRD name.
    sidecar.opentelemetry.io/inject: "workshopuser(n)-eck"
    # Container language type to inject appropriate agent.
    instrumentation.opentelemetry.io/inject-java: "true"
    # Container name to instrument
    instrumentation.opentelemetry.io/container-names: "gateway"
```
2. Update _***spec.app.bundle***_ to point to test service graphman bundles secrets. </br> __*Commnetout line 23 and Uncomment lines 24-27*__
```yaml
bundle:
  - type: graphman
    source: secret
    name: graphman-otel-test-services
```
3. Disable auto instrumentation of all libraries except jdbc and jvm runtime-metrics. Add below jvm params at _***spec.app.java.extraArgs***_.
We can enable or disable each desired instrumentation individually using -Dotel.instrumentation.[name].enabled=true/false
Complete list of supported autinstumnetation library/framework can be found [here](https://opentelemetry.io/docs/instrumentation/java/automatic/agent-config/#suppressing-specific-agent-instrumentation)
</br> __*Uncomment lines 74 to 78*__
```yaml
- -Dotel.instrumentation.common.default-enabled=false
- -Dotel.instrumentation.opentelemetry-api.enabled=true
- -Dotel.instrumentation.runtime-metrics.enabled=true
- -Dotel.instrumentation.jdbc.enabled=true
- -Dotel.instrumentation.jdbc-datasource.enabled=true
```
4. Add Open Telemetry cluster wide properties
Enable service metrics and set metric prefix. For the work shop, let the `otel.metricPrefix` be `l7_`. Also set resource attributes to capture.
Add below cwp's at _***spec.app.cwp.properties***_
</br> __*Uncomment lines 98 to 103*__
```yaml
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
1. Create configmap with script to call the test services
```
kubectl apply -f ./exercise5-resources/api-request-configmap.yaml
```

2. Create a job to execute the script.
```
kubectl apply -f ./exercise5-resources/test-services.yaml
```

### Monitor Gateway
1. Login into [Kibana](https://kibana.brcmlabs.com/) and click on 'Analytics' and then click on 'Dashboard'
2. Search for 'Layer7 Gateway Dashboard' and click on the link.
3. Select your Gateway from the 'Gateway' dropdown (workshopuser(n)-ssg)
4. You should be able to see the Gateway Service metrics along with jvm metrics on the dashboard.


### Start [Exercise 6](./lab-exercise6.md)
