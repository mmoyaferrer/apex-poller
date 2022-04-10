public with sharing class PollConfiguration {
    public String pollClass { get; private set; }
    public String checkCompletionClass { get; private set; }
    public String callbackClass { get; private set; }
    public List<IncrementalDelay> incremDelays { get; private set; }
    public Datetime startTime { get; private set; }
    public Integer timeout { get; private set; }

    // PUBLIC

    public PollConfiguration withPollAction(String className) {
        this.pollClass = className;

        return this;
    }

    public PollConfiguration withCompletionChecker(String className) {
        this.checkCompletionClass = className;

        return this;
    }

    public PollConfiguration withCallbackAction(String className) {
        this.callbackClass = className;

        return this;
    }

    public PollConfiguration addDelay(Integer iterationsCount, Integer delayInSeconds) {
        if (this.incremDelays == null) {
            this.incremDelays = new List<IncrementalDelay>();
        }
        this.incremDelays.add(new IncrementalDelay(iterationsCount, delayInSeconds));
        return this;
    }

    public PollConfiguration withStartTime(Datetime timing) {
        this.startTime = timing;

        return this;
    }

    public PollConfiguration withTimeout(Integer seconds) {
        this.timeout = seconds;

        return this;
    }

    // INNER

    public class IncrementalDelay implements Comparable {
        public Integer delayInSeconds;
        public Integer iterationsCount;

        public IncrementalDelay(Integer iterationsCount, Integer delayInSeconds) {
            this.delayInSeconds = delayInSeconds;
            this.iterationsCount = iterationsCount;
        }

        public Integer compareTo(Object compareTo) {
            IncrementalDelay inc = (IncrementalDelay) compareTo;
            Integer result = 0;
            if (iterationsCount > inc.iterationsCount) {
                result = 1;
            } else if (iterationsCount < inc.iterationsCount) {
                result = -1;
            }
            return result;
        }
    }
}
