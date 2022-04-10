public with sharing class Poller implements Schedulable {
    private Configuration configuration;
    private Integer iteration;

    // CONSTRUCTORS

    public Poller(Configuration configuration) {
        this.configuration = configuration;
        this.iteration = 1;
    }

    public Poller(Configuration configuration, Integer iteration) {
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

    // INNER

    public class Configuration {
        public String pollClass { get; private set; }
        public String checkCompletionClass { get; private set; }
        public String callbackClass { get; private set; }
        public List<IncrementalDelay> incremDelays { get; private set; }
        public Datetime startTime { get; private set; }
        public Integer timeout { get; private set; }
    
        // PUBLIC
    
        public Configuration pollWith(String className) {
            this.pollClass = className;
    
            return this;
        }
    
        public Configuration untilTrue(String className) {
            this.checkCompletionClass = className;
    
            return this;
        }
    
        public Configuration then(String className) {
            this.callbackClass = className;
    
            return this;
        }
    
        public Configuration beginning(Datetime timing) {
            this.startTime = timing;
    
            return this;
        }
    
        public Configuration timeout(Integer seconds) {
            this.timeout = seconds;
    
            return this;
        }
    
        public Configuration addDelay(Integer upperIteration, Integer delayInSeconds) {
            if (this.incremDelays == null) {
                this.incremDelays = new List<IncrementalDelay>();
            }
            this.incremDelays.add(new IncrementalDelay(upperIteration, delayInSeconds));
            return this;
        }
    }

    public class IncrementalDelay implements Comparable {
        public Integer delayInSeconds;
        public Integer upperIteration;

        public IncrementalDelay(Integer upperIteration, Integer delayInSeconds) {
            this.delayInSeconds = delayInSeconds;
            this.upperIteration = upperIteration;
        }

        public Integer compareTo(Object compareTo) {
            IncrementalDelay inc = (IncrementalDelay) compareTo;
            Integer result = 0;
            if (upperIteration > inc.upperIteration) {
                result = 1;
            } else if (upperIteration < inc.upperIteration) {
                result = -1;
            }
            return result;
        }
    }

    public class PollingException extends Exception {}
}
