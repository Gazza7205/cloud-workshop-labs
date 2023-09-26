
# Lab exercise 7
This exercise we will make of Gateway Telemetry Metric assertion to measure a custom metric. As noted in exercis 6, all the test services can take in a query parameter which denote the organization the client (caller) belongs to. Now we would like to know the usage of apis by organization. 

### This exercise requires pre-requisites
Please perform the steps [here](./readme.md#before-you-start) to configure your environment if you haven't done so yet. This exercise follows on from [exercise 6](./lab-exercise6.md), we will re-use the test services.

## Key concepts
- [Create mssage complete policy](#create-message-complete-policy)
- [Configuring the Gateway](#configuring-the-gateway)
- [Update the Gateway](#update-the-gateway)
- [Call Test services](#call-test-services)
- [Moitor Gateway](#moitor-gateway)

### Create messge complete policy
Create a message complete policy with Telemetry Metric assertion. Select the type to be counter and attributes service.name, service.oid and service.resolutionUri
Get organization id from request parameter, if not present set it to 'NONE'

Create a configmap containing the policy.
```
kubectl create secret generic graphman-otel-message-complete --from-file=./exercise7-resources/otel_message_complete.json
```

<kbd><img src="https://github.com/Gazza7205/cloud-workshop-labs/assets/59958248/c5d0f49a-5a12-46c8-9c9b-ad2a03a38a15" /></kbd>

### Configuring the Gateway
We can now create/update our Gateway Custom Resource with the bundles and OTel related configuration.
The base CRD can be found [here](/exercise7-resources/gateway.yaml).

1. Add message complete secret bundle to spec.app.bundle 
```
bundle:
  - type: graphman
    source: secret
    name: graphman-otel-test-services
  - type: graphman
    source: secret
    name: graphman-otel-message-complete
```

### Update the Gateway
Now that we've configured our Gateway Custom Resource to make Gateway Observable we can now send the updated manifest into Kubernetes. The Layer7 Operator will then reconcile our new desired state with reality.

1. Update the Gateway CR
```
kubectl apply -f ./exercise7-resources/gateway.yaml
```
### Call Test services.
To generate some load, we will reuse ths job from exercise6.

1. Delete the job if already present (created as part of exercise6)
```
kubectl delete job api-requests
```
2. Submit the job
```
kubectl apply -f ./exercise6-resources/test-services.yaml
```
### Moitor Gateway
1. Login into [Kibana](https://kibana.brcmlabs.com/) and click on 'Analytics' and then click on 'Dashboard'
2. Search for 'Usage By Org' and click on the link.
3. Select the Gateway you would to moniter in 'Gateway' dropdown (workshopuser(n)-ssg)
4. You should be able to chart with api usage by organization.


### Start [Exercise 7](./lab-exercise7.md)
