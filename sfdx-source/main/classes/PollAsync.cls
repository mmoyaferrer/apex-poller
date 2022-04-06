public with sharing class PollAsync implements Queueable, Database.AllowsCallouts {
    private PollConfiguration configuration;
    private Integer iteration;

    // CONSTRUCTOR

    public PollAsync(PollConfiguration configuration, Integer iteration) {
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
            throw new PollException('Invalid class ' + fullClassName);
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

    private String calculateNextFireCron(Integer iteration, PollConfiguration configuration) {
        Datetime now = Datetime.now();

        validateTimeout(configuration, now);
        List<PollConfiguration.IncrementalDelay> incrementalDelays = configuration.incremDelay;
        incrementalDelays.sort();
        Datetime nextTime;
        if (incrementalDelays != null && incrementalDelays.size() > 0) {
            PollConfiguration.IncrementalDelay currentDelay = closestDelay(iteration, incrementalDelays);
            nextTime = now.addSeconds(currentDelay.delayInSeconds);
        } else if (configuration.staticDelay != null) {
            nextTime = now.addSeconds(configuration.staticDelay);
        } else {
            throw new PollException('Neither static delay or incremental delay are defined for PollConfiguration');
        }

        return cronFrom(nextTime);
    }

    private void validateTimeout(PollConfiguration configuration, Datetime now) {
        Long nowMs = now.getTime();
        Long startTimeMs = configuration.startTime.getTime();

        Integer differenceSeconds = (Integer) ((nowMs - startTimeMs) / 1000);
        if (differenceSeconds >= configuration.timeout) {
            throw new PollException('Polling timeout reached');
        }
    }

    private PollConfiguration.IncrementalDelay closestDelay(
        Integer iteration,
        List<PollConfiguration.IncrementalDelay> incrementalDelays
    ) {
        PollConfiguration.IncrementalDelay[] cleanDelays = new List<PollConfiguration.IncrementalDelay>();
        for (PollConfiguration.IncrementalDelay delay : incrementalDelays) {
            if (delay.iterationsCount > iteration) {
                cleanDelays.add(delay);
            }
        }
        PollConfiguration.IncrementalDelay currentDelay = cleanDelays[0];
        Integer diff = Math.abs(iteration - currentDelay.iterationsCount);
        for (Integer val = 0; val < cleanDelays.size(); val++) {
            Integer newdiff = Math.abs(iteration - cleanDelays[val].iterationsCount);
            if (newdiff < diff) {
                diff = newdiff;
                currentDelay = cleanDelays[val];
            }
        }
        return currentDelay;
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

    // INNER

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
            if (context.getResult() == ParentJobResult.UNHANDLED_EXCEPTION && ex.getTypeName() != 'PollException') {
                System.debug('An unhandled exception happened: ' + ex.getMessage());
                System.debug(ex.getStackTraceString());
                System.debug('Scheduling again (up to 5 times)...');
                outerClass.scheduleAgain();
            }
        }
    }
}
