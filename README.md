# Apex Poller Framework

This framework provides a simple and guided way to implement a polling mechanism for long running processes in Salesforce. Applicable to any long-running process, such as Http polling but not limited to it.

By injecting 3 apex classes, will run a polling mechanism based on 3 steps:
-   1) Execute the polling logic
-   2) Evaluate the response (automatically rescheduling itself into a new poll if it's not the expected one)
-   3) Execute callback logic when finished

## Samples
### Random number checker

Let's say we want to poll a random number API until we get the number 3.

For that, we can invoke a polling like below (script also in `dev-tools/apex-scripts/run-number-checker-sample`):
```
new Poll(new RequestNumber())
    .untilTrue(new NumberChecker())
    .then(new CorrectNumberCallback())
    .incrementalDelaysPreset()
    .execute();
).execute();
```
Where:
- By `pollWith` we specify the polling logic:

```
public with sharing class RequestNumber implements Callable {
    public Object call(String action, Map<String, Object> args) {
        HttpRequest request = new HttpRequest()
        request.setMethod('GET');
        request.setEndpoint('http://www.randomnumberapi.com/api/v1.0/random?min=1&max=10');
        HttpResponse response = new Http().send(request);

        return (Object) JSON.deserializeUntyped(response.getBody());
    }
}
```

- By `untilTrue`, we specify our logic with the condition to finish:

```
public with sharing class NumberChecker implements Callable {
    public Object call(String action, Map<String, Object> args) {
        List<Object> httpResponseObjects = (List<Object>) args.get('default');
        Integer numberFound = (Integer) httpResponseObjects[0];

        return numberFound == 3;
    }
}
```

- By `then`, we specify what to do when the number is found (callback):
```
public with sharing class CorrectNumberCallback implements Callable {
    public Object call(String action, Map<String, Object> args) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setToAddresses(new List<String>{ '<your-email>' });
        mail.setReplyTo('<your-email>');
        mail.setSenderDisplayName('Default Name');
        mail.setSubject('Found the number!');
        mail.setPlainTextBody('We found the expected number: ' + args.get('default'));

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });

        return null;
    }
}
```
- By `incrementalDelaysPreset` we use built-in delay system, where:
    - For the first 10 iterations, the delay time will be 15 seconds
    - For 10th to 30th iterations, the delay time will be 30 seconds
    - For rest of iterations, the delay time will be 120 seconds

- As an alternative to the incremental delay preset, there are other options for setting granular delays:
    - 1º Setting a static delay with `staticDelay(x)` where `x` represents the delay in seconds
    - 2º Building a custom incremental delay by using `addDelay`. By using it, we specify the delay in seconds until a specific iteration, i.e:
        - `.addDelay(5, 10)` Until 5th iteration, the delay will be 10 seconds
        - `.addDelay(10, 20)` Until 10th iteration, the delay will be 20 seconds (does not overwrite the first 5 iterations delay)
        - `.addDelay(30, 180)` Until 30th iteration, the delay will be 180 seconds (does not overwrite the first 10 iterations delay). As this is the final delay, will be taken into account even if the iteration is > 30, until `timeout` is reached.
        - Note: Delays will be sorted automatically in ascending order, by nº of iterations, i.e 5-10-30