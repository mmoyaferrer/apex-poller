public with sharing class PollAsync implements Queueable, Database.AllowsCallouts {
   
    private PollConfiguration configuration;
    private Integer iteration;

    // PUBLIC
    
    public PollAsync(PollConfiguration configuration, Integer iteration) {
        this.configuration = configuration;
        this.iteration = iteration;
    }
    
    public void execute(QueueableContext context) {
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
        return ((Callable) callbackClass.newInstance()).call('', new Map<String, Object>{'default' => args});
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
        // @TODO: Manage timeout
        // if (iteration.totalTime > configuration.timeout) {
        //     throw new PollException('Polling Timeout reached');
        // }

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
        Datetime nextTime = Datetime.now();

        if (configuration.incremDelay != null) {
            if (iteration <= configuration.incremDelay.initialDelayIterations) {
            nextTime = nextTime.addSeconds(configuration.incremDelay.initialDelay);
            } else if (iteration <= configuration.incremDelay.initialDelayIterations + configuration.incremDelay.middleDelayIterations) {
                nextTime = nextTime.addSeconds(configuration.incremDelay.middleDelay);
            } else {
                nextTime = nextTime.addSeconds(configuration.incremDelay.finalDelay);
            }
        } else if (configuration.staticDelay != null) {
            nextTime = nextTime.addSeconds(configuration.staticDelay);
        } else {
            throw new PollException('Neither static delay or incremental delay are defined for PollConfiguration');
        }

        return cronFrom(nextTime);
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
}
