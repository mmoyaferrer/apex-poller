public with sharing class PollConfiguration {
    public String pollClass { get; private set; }
    public String checkCompletionClass { get; private set; }
    public String callbackClass { get; private set; }
    public List<IncrementalDelay> incremDelays { get; private set; }
    public Datetime startTime { get; private set; }
    public Integer timeout { get; private set; }

    // PUBLIC

    public PollConfiguration pollWith(String className) {
        this.pollClass = className;

        return this;
    }

    public PollConfiguration untilTrue(String className) {
        this.checkCompletionClass = className;

        return this;
    }

    public PollConfiguration then(String className) {
        this.callbackClass = className;

        return this;
    }

    public PollConfiguration beginning(Datetime timing) {
        this.startTime = timing;

        return this;
    }

    public PollConfiguration timeout(Integer seconds) {
        this.timeout = seconds;

        return this;
    }

    public PollConfiguration addDelay(Integer upperIteration, Integer delayInSeconds) {
        if (this.incremDelays == null) {
            this.incremDelays = new List<IncrementalDelay>();
        }
        this.incremDelays.add(new IncrementalDelay(upperIteration, delayInSeconds));
        return this;
    }

    // INNER

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
}
