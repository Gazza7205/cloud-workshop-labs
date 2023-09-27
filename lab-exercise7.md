
# Lab exercise 7
This exercise we will make of Gateway Telemetry Tracing and identify the reason for a service failure. We have already created a sample error service as part of exercise 6 (/test5) 

### This exercise requires pre-requisites
Please perform the steps [here](./readme.md#before-you-start) to configure your environment if you haven't done so yet. This exercise follows on from [exercise 6](./lab-exercise6.md), we will re-use the test services.

## Key concepts
- [Enable Tracing on Gateway](#enable-tracing-on-gateway)
- [Update the Gateway](#update-the-gateway)
- [Trace service on Jaeger](#trace-service-on-jaeger)

### Enable Tracing on Gateway
We would like to control the amount of tracing so that it does not affect the Gateway performance and backend(Jaeger/Elastic search etc) disk space.
In gateway we can enable and disable the trace using cwp `otel.traceEnabled`. Also, we need to configure which service to trace. This can be configured using `otel.traceConfig` cwp. This should in a json format. 
1. Service(s) to trace can be specified by the url (regx) or service uid.
2. Each assertion executed under a service trace is represented as a span. We can include/exclude the assertions to trace. Some assertions like 'SetVariable' may not be needed to be traced and can be included.
3. Each span/assertion optionally have array of events/logs. They represent the context variables with values at the end of assertion execution. The assertion which need to trace the context variables need to be specified. By default none of the spans will have events with context variable values.

Lets enable the trace for our service using url regx and also trace all context variables. We will exclude "Set Variable" assertion to reduce the noise.
Add below cpws to Gateway custom resource at  _***spec.app.cwp.properties***_. 

Continue using the Gateway CRD file from exercise6 [here](/exercise6-resources/gateway.yaml).

```
      - name: otel.traceEnabled
        value: "true"
      - name: otel.traceConfig
        value: |
            {
              "services": [
                {"url": ".*/test.*"}
              ],
              "assertions": {
                "exclude" : ["SetVariable"]
              },
              "contextVariables": {
                "assertions" : [".*"]
              }
            }
```

### Update the Gateway
Apply the changes made to Gateway custom resource. 

1. Update the Gateway CR
```
kubectl apply -f ./exercise7-resources/gateway.yaml
```
2. As there is only an cwp changes. The gateway pod will not restart and hence pod need to deleted manually. In production, cwp change can be applied using a repository/graphman or restman

Get pod name
```
kubectl get pods --no-headers -o custom-columns=":metadata.name" -l app.kubernetes.io/name=ssg
```
Copy output from above command and use it to delete the pod. The Gateway operator will recreate the pod.
```
kubectl delete pod xxxx
```
3. Once the gateway is up, Call the test service.
```
kubectl get svc

NAME  TYPE           CLUSTER-IP     EXTERNAL-IP         PORT(S)                         AGE
ssg   LoadBalancer   10.68.4.161    ***34.89.84.69***   8443:31747/TCP,9443:30778/TCP   41m

if your output looks like this that means you don't have an External IP Provisioner in your Kubernetes Cluster. You can still access your Gateway using port-forward.

NAME  TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)                         AGE
ssg   LoadBalancer   10.68.4.126   <PENDING>       8443:31384/TCP,9443:31359/TCP   7m39s
```

If EXTERNAL-IP is stuck in \<PENDING> state
```
kubectl port-forward svc/ssg 9443:9443
```

```
curl https://34.89.84.69:8443/test5 -k

or if you used port-forward

curl https://localhost:9443/test5 -H "-k
```

### Trace service on Jaeger
1. Open [Jaeger](https://jaeger.brcmlabs.com/)
2. Select the your service under Service dropdown (workshopuser(n)-ssg)
3. Select 'age' in 'Operation' drop down box. The service name is age and url is /test5
4. Select appropriate 'Lookback' time and click on 'Find Traces'
5. Should result in some traces for the service. Click on any one of them.
6. Walk through the spans and check for errors. Here, there is a javascript assertion error

<kbd><img src="https://github.com/Gazza7205/cloud-workshop-labs/assets/59958248/5ff8a008-68e3-427f-8270-b33f1fc8e34b" /></kbd>

### Start [Exercise 8](./lab-exercise8.md)