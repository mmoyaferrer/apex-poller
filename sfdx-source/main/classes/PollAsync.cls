public with sharing class PollAsync implements Queueable, Database.AllowsCallouts {
   
    private PollConfiguration configuration;
    private Integer iteration;

    // PUBLIC
    
    public PollAsync(PollConfiguration configuration, Integer iteration) {
        this.configuration = configuration;
        this.iteration = iteration;
    }
    
    public void execute(QueueableContext context) {
        HttpRequest request = new HttpRequest();
        request.setMethod(configuration.method);
        request.setEndpoint(configuration.endpoint);
        HttpResponse response = new Http().send(request);

        Object httpResponseBody = (Object) JSON.deserializeUntyped(response.getBody());

        Boolean completed = checkCompleted(httpResponseBody);

        System.debug('completed?: ' + completed);

        if (completed) {
            invokeCallback(httpResponseBody);
        } else {
            scheduleAgain();
        }     
    }

    // PRIVATE

    private void scheduleAgain() {
        // @TODO: Manage timeout
        // if (iteration.totalTime > configuration.timeout) {
        //     throw new PollException('Polling Timeout reached');
        // }

        try {
            String nextFireCron = calculateNextFireCron(iteration, configuration);
            
            iteration++;
            Poller scheduledPoll = new Poller(configuration, iteration);

            System.schedule('Polling - ' + nextFireCron, nextFireCron, scheduledPoll);
        } catch (AsyncException ex) {
            if (!Test.isRunningTest()) {
                throw ex;
            }
        }
    }

    private String calculateNextFireCron(Integer iteration, PollConfiguration configuration) {
        Datetime nextTime = Datetime.now();

        System.debug('iteration: ' + iteration);
        System.debug('current time: ' + nextTime);

        if (configuration.incremDelay != null) {
            if (iteration <= configuration.incremDelay.initialDelayIterations) {
            nextTime = nextTime.addSeconds(configuration.incremDelay.initialDelay);
            } else if (iteration <= configuration.incremDelay.initialDelayIterations + configuration.incremDelay.middleDelayIterations) {
                nextTime = nextTime.addSeconds(configuration.incremDelay.middleDelay);
            } else {
                nextTime = nextTime.addSeconds(configuration.incremDelay.finalDelay);
            }
        } else if (configuration.staticDelay != null) {
            nextTime = nextTime.addSeconds(configuration.staticDelay);
        } else {
            throw new PollException('Neither static delay or incremental delay are defined for PollConfiguration');
        }

        System.debug('next time: ' + nextTime);


        return cronFrom(nextTime);
    }

    private String cronFrom(Datetime dateItem) {
        String year = String.valueOf(dateItem.year());
        String month = String.valueOf(dateItem.month());
        String day = String.valueOf(dateItem.day());
        String hour = String.valueOf(dateItem.hour());
        String min = String.valueOf(dateItem.minute());
        String second = String.valueOf(dateItem.second());

        return second + ' ' + min + ' ' + hour + ' ' + day + ' ' + month + ' ' + '?' + ' ' + year;
    }

    private Boolean checkCompleted(Object httpResponseBody) {
        Type callbackClass = typeByName(configuration.checkCompletionClass);
        Object callableResponse = ((Callable) callbackClass.newInstance()).call('', new Map<String, Object>{'default' => httpResponseBody});

        return (Boolean) callableResponse;
    }

    private void invokeCallback(Object httpResponseBody) {
        if (String.isNotBlank(configuration.callbackClass)) {
            Type callbackClass = typeByName(configuration.callbackClass);
            ((Callable) callbackClass.newInstance()).call('', new Map<String,Object>{'default' => httpResponseBody});
        }
    }

    private Type typeByName(String fullClassName) {
        String namespace = fullClassName.contains('.') ? fullClassName.substringBefore('.') : '';
        String className = fullClassName.contains('.') ? fullClassName.substringAfter('.') : fullClassName;

        Type result = Type.forName(namespace, className);

        if (result == null) {
            throw new PollException('Invalid class ' + fullClassName);
        }

        return result;
    }
}
