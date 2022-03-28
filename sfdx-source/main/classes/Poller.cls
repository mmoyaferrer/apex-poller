public with sharing class Poller implements Schedulable {
   
    private PollConfiguration configuration;
    private Integer iteration;

    // PUBLIC
    
    public Poller(PollConfiguration configuration) {
        this.configuration = configuration;
        this.iteration = 1;
    }

    public Poller(PollConfiguration configuration, Integer iteration) {
        this.configuration = configuration;
        this.iteration = iteration;
    }
    
    public void start() {
        System.enqueueJob(new PollAsync(configuration, iteration));
    }

    public void execute(SchedulableContext schedulableContext) {
        System.enqueueJob(new PollAsync(configuration, iteration));
    }

}
