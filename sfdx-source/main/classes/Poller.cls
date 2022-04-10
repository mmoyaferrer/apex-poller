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

    public class PollAsync implements Queueable, Database.AllowsCallouts {
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
    
            Object pollResponse = invokeClass(configuration.pollClass, null);
            Boolean completed = (Boolean) invokeClass(configuration.checkCompletionClass, pollResponse);
    
            if (completed) {
                invokeClass(configuration.callbackClass, pollResponse);
            } else {
                scheduleAgain();
            }
        }
    
        // PRIVATE
    
        private Object invokeClass(String className, Object args) {
            Type callbackClass = typeByName(className);
            return ((Callable) callbackClass.newInstance()).call('', new Map<String, Object>{ 'default' => args });
        }
    
        private Type typeByName(String fullClassName) {
            String namespace = fullClassName.contains('.') ? fullClassName.substringBefore('.') : '';
            String className = fullClassName.contains('.') ? fullClassName.substringAfter('.') : fullClassName;
    
            Type result = Type.forName(namespace, className);
    
            if (result == null) {
                throw new PollingException('Invalid class ' + fullClassName);
            }
    
            return result;
        }
    
        private void scheduleAgain() {
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
    
        private String calculateNextFireCron(Integer iteration, Configuration configuration) {
            Datetime now = Datetime.now();
            validateTimeout(configuration, now);
    
            System.debug('iteration: ' + iteration);
            System.debug('now: ' + now);
    
            List<IncrementalDelay> incrementalDelays = configuration.incremDelays;
            incrementalDelays.sort();
    
            Datetime nextTime;
            if (incrementalDelays != null && incrementalDelays.size() > 0) {
                IncrementalDelay nextDelay = nextDelay(iteration, incrementalDelays);
                nextTime = now.addSeconds(nextDelay.delayInSeconds);
            } else {
                throw new PollingException('Delay/s not defined');
            }
    
            System.debug('next: ' + nextTime);
    
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

    public class PollingException extends Exception {}
}
