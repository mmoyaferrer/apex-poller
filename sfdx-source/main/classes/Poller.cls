public with sharing class Poller implements Schedulable {
   
    private PollConfiguration parameters;

    // PUBLIC
    
    public Poller(PollConfiguration parameters) {
        this.parameters = parameters;
    }
    
    public void start() {
        System.enqueueJob(new PollAsync(parameters));
    }

    public void execute(SchedulableContext schedulableContext) {
        System.enqueueJob(new PollAsync(parameters));
    }

}
