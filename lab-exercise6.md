
# Lab exercise 6
This exercise we will make use of Gateway Telemetry Metric assertion to measure a custom metric. As noted in exercise 6, all the test services take a query parameter which denote the organization to which client (caller) belongs to. Now we would like to know the usage of apis by organization. 

### This exercise requires pre-requisites
Please perform the steps [here](./readme.md#before-you-start) to configure your environment if you haven't done so yet. This exercise follows on from [exercise 5](./lab-exercise5.md), and is a pre-requisite.

## Key concepts
- [Create message complete policy](#create-message-complete-policy)
- [Configuring the Gateway](#configuring-the-gateway)
- [Update the Gateway](#update-the-gateway)
- [Call Test services](#call-test-services)
- [Monitor Gateway](#monitor-gateway)

### Create message complete policy
Create a message complete policy with Telemetry Metric assertion. Select the type to be counter and attributes service.name, service.oid and service.resolutionUri
Get organization id from request parameter, if not present set it to 'NONE'

Create a configmap containing the policy.
```
kubectl create secret generic graphman-otel-message-complete --from-file=./exercise6-resources/otel_message_complete.json
```

<kbd><img src="https://github.com/Gazza7205/cloud-workshop-labs/assets/59958248/c5d0f49a-5a12-46c8-9c9b-ad2a03a38a15" /></kbd>

### Configuring the Gateway
Continue using the Gateway CRD file from exercise5 [here](/exercise5-resources/gateway.yaml)

1. Add message complete secret bundle to _***spec.app.bundle***_
</br> __* Uncomment lines 28 to 30 *__
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
Apply the changes made to Gateway custom resource. The Layer7 Operator will then reconcile our new desired state with reality.

1. Update the Gateway CR and verify that the gateway pod is restarted.
```
kubectl apply -f ./exercise5-resources/gateway.yaml
```
```
kubectl get pods
```
Verify the age of ssg pod
```
NAME                                                  READY   STATUS      RESTARTS       AGE
api-requests-5bvx2                                    0/1     Completed   0              5m38s
layer7-operator-controller-manager-7c996ccfb6-9qsw6   2/2     Running     1 (108m ago)   109m
ssg-56ff97b54d-nsx86                                  2/2     Running     0              116s
```
### Call Test services.
To generate some load, we will reuse the job from exercise6.

1. Delete the job if already present (created as part of exercise6)
```
kubectl delete job api-requests
```
2. Submit the job
```
kubectl apply -f ./exercise5-resources/test-services.yaml
```
### Monitor Gateway
1. Login into [Kibana](https://kibana.brcmlabs.com/) and click on 'Analytics' and then click on 'Dashboard'
2. Search for 'Usage By Org' and click on the link.
3. Select the Gateway you would like to monitor in 'Gateway' dropdown (workshopuser(n)-ssg)
4. You should be able to see chart with api usage by organization as below.

<kbd><img src="https://github.com/Gazza7205/cloud-workshop-labs/assets/59958248/3084109f-fbb0-4471-986c-f8b71d65b819" /></kbd>


### Start [Exercise 7](./lab-exercise7.md)
