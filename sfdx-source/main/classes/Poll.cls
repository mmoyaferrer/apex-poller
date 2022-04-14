public with sharing class Poll implements Schedulable {
    @TestVisible
    private Integer iteration;
    private Configuration configuration;

    // CONSTRUCTORS

    public Poll(Callable instance) {
        this.configuration = new Configuration();

        this.configuration.pollInstance = instance;
        this.iteration = 1;
    }

    public Poll(Configuration configuration, Integer iteration) {
        this.configuration = configuration;
        this.iteration = iteration;
    }

    // PUBLIC

    public Poll untilTrue(Callable instance) {
        this.configuration.checkCompletionInstance = instance;

        return this;
    }

    public Poll then(Callable instance) {
        this.configuration.callbackInstance = instance;

        return this;
    }

    public Poll beginning(Datetime timing) {
        this.configuration.startTime = timing;

        return this;
    }

    public Poll timeout(Integer seconds) {
        this.configuration.timeout = seconds;

        return this;
    }

    public Poll staticDelay(Integer delayInSeconds) {
        return this.addDelay(1, delayInSeconds);
    }

    public Poll incrementalDelaysPreset() {
        return this.addDelay(10, 15)
            .addDelay(30, 30)
            .addDelay(100, 120);
    }

    public Poll addDelay(Integer upperIteration, Integer delayInSeconds) {
        if (this.configuration.incremDelays == null) {
            this.configuration.incremDelays = new List<IncrementalDelay>();
        }
        this.configuration.incremDelays.add(new IncrementalDelay(upperIteration, delayInSeconds));
        return this;
    }

    public void execute() {
        execute(null);
    }

    public void execute(SchedulableContext schedulableContext) {
        System.enqueueJob(new PollAsync(configuration, iteration));
    }


    // INNER

    public with sharing class Configuration {
        private Callable pollInstance { get; private set; }
        private Callable checkCompletionInstance { get; private set; }
        private Callable callbackInstance { get; private set; }
        private List<IncrementalDelay> incremDelays { get; private set; }
        private Datetime startTime { get; private set; }
        private Integer timeout { get; private set; }

        public Configuration() {
            this.startTime = Datetime.now();
            this.timeout = 86400;
        }
    }

    private with sharing class IncrementalDelay implements Comparable {
        private Integer delayInSeconds;
        private Integer upperIteration;

        public IncrementalDelay(Integer upperIteration, Integer delayInSeconds) {
            this.delayInSeconds = delayInSeconds;
            this.upperIteration = upperIteration;
        }

        public Integer compareTo(Object compareTo) {
            IncrementalDelay inc = (IncrementalDelay) compareTo;
            return upperIteration > inc.upperIteration ? -1 : (upperIteration < inc.upperIteration) ? -1 : 0;
        }
    }

    @TestVisible
    private with sharing class PollAsync implements Queueable, Database.AllowsCallouts {
        private Configuration configuration;
        private Integer iteration;
    
        // CONSTRUCTOR
    
        public PollAsync(Configuration configuration, Integer iteration) {
            this.configuration = configuration;
            this.iteration = iteration;
        }
    
        // PUBLIC


        public void execute(QueueableContext context) {
            PollAsyncFinalizer finalizer = new PollAsyncFinalizer(this);
            System.attachFinalizer(finalizer);
    
            Object pollResponse = invokeClass(configuration.pollInstance, null);
            Boolean completed = (Boolean) invokeClass(configuration.checkCompletionInstance, pollResponse);
    
            if (completed) {
                invokeClass(configuration.callbackInstance, pollResponse);
            } else {
                scheduleAgain();
            }
        }
    
        // PRIVATE
    
        private Object invokeClass(Callable instance, Object args) {
            return instance.call('', new Map<String, Object>{ 'default' => args });
        }

        private void scheduleAgain() {
            try {
                String nextFireCron = calculateNextFireCron(iteration, configuration);
    
                iteration++;
                Poll scheduledPoll = new Poll(configuration, iteration);
                System.schedule('Polling - ' + nextFireCron, nextFireCron, scheduledPoll);
            } catch (AsyncException ex) {
                if (!Test.isRunningTest()) {
                    throw ex;
                }
            }
        }
    
        private String calculateNextFireCron(Integer iteration, Configuration configuration) {
            Datetime now = Datetime.now();
            validateTimeout(configuration, now);

            List<IncrementalDelay> incrementalDelays = configuration.incremDelays;
            incrementalDelays.sort();
    
            Datetime nextTime;
            if (incrementalDelays != null && incrementalDelays.size() > 0) {
                IncrementalDelay nextDelay = nextDelay(iteration, incrementalDelays);
                nextTime = now.addSeconds(nextDelay.delayInSeconds);
            } else {
                throw new PollingException('Delay/s not defined');
            }

            return cronFrom(nextTime);
        }
    
        private void validateTimeout(Configuration configuration, Datetime now) {
            Long nowMs = now.getTime();
            Long startTimeMs = configuration.startTime.getTime();
    
            Integer differenceSeconds = (Integer) ((nowMs - startTimeMs) / 1000);
            if (differenceSeconds >= configuration.timeout) {
                throw new PollingException('Polling timeout reached');
            }
        }
    
        private IncrementalDelay nextDelay(
            Integer iteration,
            List<IncrementalDelay> incrementalDelays
        ) {
    
            IncrementalDelay result;
     
            for (IncrementalDelay delay : incrementalDelays) {
                if (delay.upperIteration >= iteration) {
                    result = delay;
                    break;
                }
            }
    
            return result != null ? result : incrementalDelays[incrementalDelays.size() - 1];
        }
    
        private String cronFrom(Datetime dateItem) {
            return dateItem.second() + ' ' + dateItem.minute() + ' ' + dateItem.hour() + ' ' + dateItem.day() + ' ' + dateItem.month() + ' ' + '?' + ' ' + dateItem.year();
        }
    
    }    

    private with sharing class PollAsyncFinalizer implements Finalizer {
        private PollAsync outerClass;

        // CONSTRUCTOR

        // Note: this is to overcome a non anologous Java limitation.
        // See: https://developer.salesforce.com/forums/?id=906F0000000BTo1IAG
        // See: https://salesforce.stackexchange.com/questions/101056/how-to-call-outerclass-method-in-a-wrapper-class
        private PollAsyncFinalizer(PollAsync outerClass) {
            this.outerClass = outerClass;
        }

        public void execute(System.FinalizerContext context) {
            Exception ex = context.getException();
            if (context.getResult() == ParentJobResult.UNHANDLED_EXCEPTION && ex.getTypeName() != 'PollingException') {
                System.debug('An unhandled exception happened: ' + ex.getMessage());
                System.debug(ex.getStackTraceString());
                System.debug('Scheduling again (up to 5 times)...');
                outerClass.scheduleAgain();
            }
        }
    }

    @TestVisible
    private with sharing class PollingException extends Exception {}
}
