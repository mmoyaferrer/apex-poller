public with sharing class PollConfiguration {
    public String pollClass;
    public String checkCompletionClass;
    public String callbackClass;

    public Integer staticDelay;
    public IncrementalDelay incremDelay;

    public Integer timeout;

    public PollConfiguration withStaticDelay(Integer delay) {
        staticDelay = delay;

        return this;
    }

    public PollConfiguration withIncrementalDelay(IncrementalDelay delay) {
        incremDelay = delay;

        return this;
    }

    public class IncrementalDelay {
        public Integer initialDelay;
        public Integer initialDelayIterations;

        public Integer middleDelay;
        public Integer middleDelayIterations;
        
        public Integer finalDelay;

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
