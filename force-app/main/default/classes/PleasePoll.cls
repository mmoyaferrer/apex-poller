public with sharing class PleasePoll implements Queueable, Database.AllowsCallouts {
   
    private PollingParameters parameters;

    // PUBLIC
    
    public PleasePoll(PollingParameters parameters) {
        this.parameters = parameters;
    }
    
    public void execute(QueueableContext context) {
        HttpRequest request = new HttpRequest();
        request.setMethod(parameters.method);
        request.setEndpoint(parameters.endpoint);
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
        PleasePollAgain initialScheduledPoll = new PleasePollAgain(parameters);

        String year = String.valueOf(Datetime.now().year());
        String month = String.valueOf(Datetime.now().month());
        String day = String.valueOf(Datetime.now().day());
        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().minute()); 
        String second = String.valueOf(Datetime.now().addSeconds(10).second());

        String nextFireTime = second + ' ' + min + ' ' + hour + ' ' + day + ' ' + month + ' ' + '?' + ' ' + year;

        System.schedule('Polling - ' + nextFireTime, nextFireTime, initialScheduledPoll);
    }

    private Boolean checkCompleted(Object httpResponseBody) {
        Type callbackClass = typeByName(parameters.checkCompletionClass);
        return ((CheckCompletionI) callbackClass.newInstance()).execute(httpResponseBody);
    }

    private void invokeCallback(Object httpResponseBody) {
        if (String.isNotBlank(parameters.callbackClass)) {
            Type callbackClass = typeByName(parameters.callbackClass);
            ((AfterPollI) callbackClass.newInstance()).execute(httpResponseBody);
        }
    }

    private Type typeByName(String fullClassName) {
        String namespace = fullClassName.contains('.') ? fullClassName.substringBefore('.') : '';
        String className = fullClassName.contains('.') ? fullClassName.substringAfter('.') : fullClassName;

        Type result = Type.forName(namespace, className);

        if (result == null) {
            throw new ApplicationException('Invalid class ' + fullClassName);
        }

        return result;
    }
}
