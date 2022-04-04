public with sharing class PollConfiguration {
    public String pollClass { get; private set; }
    public String checkCompletionClass { get; private set; }
    public String callbackClass { get; private set; }
    public Integer staticDelay { get; private set; }
    public IncrementalDelay incremDelay { get; private set; }
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

    public PollConfiguration withStaticDelay(Integer seconds) {
        this.staticDelay = seconds;

        return this;
    }

    public PollConfiguration withIncrementalDelay(IncrementalDelay delay) {
        this.incremDelay = delay;

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

    public class IncrementalDelay {
        public Integer initialDelay { get; private set; }
        public Integer initialDelayIterations { get; private set; }

        public Integer middleDelay { get; private set; }
        public Integer middleDelayIterations { get; private set; }

        public Integer finalDelay { get; private set; }

        public IncrementalDelay withInitialIterations(Integer seconds, Integer iterationsCount) {
            initialDelay = seconds;
            initialDelayIterations = iterationsCount;

            return this;
        }

        public IncrementalDelay withMiddleIterations(Integer seconds, Integer iterationsCount) {
            middleDelay = seconds;
            middleDelayIterations = iterationsCount;

            return this;
        }

        public IncrementalDelay withFinalIterations(Integer seconds) {
            finalDelay = seconds;

            return this;
        }
    }
}
