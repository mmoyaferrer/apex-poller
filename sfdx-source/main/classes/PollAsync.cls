public with sharing class PollAsync implements Queueable, Database.AllowsCallouts {
   
    private PollConfiguration configuration;

    // PUBLIC
    
    public PollAsync(PollConfiguration configuration) {
        this.configuration = configuration;
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
        Poller initialScheduledPoll = new Poller(configuration);

        // @TODO: Add incremental polling
        String year = String.valueOf(Datetime.now().year());
        String month = String.valueOf(Datetime.now().month());
        String day = String.valueOf(Datetime.now().day());
        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().minute()); 
        String second = String.valueOf(Datetime.now().addSeconds(10).second());

        String nextFireTime = second + ' ' + min + ' ' + hour + ' ' + day + ' ' + month + ' ' + '?' + ' ' + year;

        try {
            System.schedule('Polling - ' + nextFireTime, nextFireTime, initialScheduledPoll);
        } catch (AsyncException ex) {
            if (!Test.isRunningTest()) {
                throw ex;
            }
        }
    }

    private Boolean checkCompleted(Object httpResponseBody) {
        Type callbackClass = typeByName(configuration.checkCompletionClass);
        return ((PollCompletionCheckerI) callbackClass.newInstance()).execute(httpResponseBody);
    }

    private void invokeCallback(Object httpResponseBody) {
        if (String.isNotBlank(configuration.callbackClass)) {
            Type callbackClass = typeByName(configuration.callbackClass);
            ((PollFinishCallbackI) callbackClass.newInstance()).execute(httpResponseBody);
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
