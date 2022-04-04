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

        Datetime nextTime;
        if (configuration.incremDelay != null) {
            PollConfiguration.IncrementalDelay delay = configuration.incremDelay;
            Integer totalMiddleIterations = delay.initialDelayIterations + delay.middleDelayIterations;

            if (iteration <= delay.initialDelayIterations) {
                nextTime = now.addSeconds(delay.initialDelay);
            } else if (iteration <= totalMiddleIterations) {
                nextTime = now.addSeconds(delay.middleDelay);
            } else {
                nextTime = now.addSeconds(delay.finalDelay);
            }
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
