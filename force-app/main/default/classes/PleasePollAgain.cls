public with sharing class PleasePollAgain implements Schedulable {

    private PollingParameters parameters;

    // PUBLIC

    public PleasePollAgain(PollingParameters parameters) {
        this.parameters = parameters;
    }

    public void execute(SchedulableContext schedulableContext) {
        System.enqueueJob(new PleasePoll(parameters));
    }

}
