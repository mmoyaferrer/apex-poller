public with sharing class Poller implements Schedulable {
    private PollConfiguration configuration;
    private Integer iteration;

    // CONSTRUCTORS

    public Poller(PollConfiguration configuration) {
        this.configuration = configuration;
        this.iteration = 1;
    }

    public Poller(PollConfiguration configuration, Integer iteration) {
        this.configuration = configuration;
        this.iteration = iteration;
    }

    // PUBLIC

    public void execute() {
        configuration.beginning(Datetime.now());

        execute(null);
    }

    public void execute(SchedulableContext schedulableContext) {
        System.enqueueJob(new PollAsync(configuration, iteration));
    }
}
