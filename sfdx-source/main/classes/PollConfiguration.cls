public with sharing class PollConfiguration {
    public String method;
    public String endpoint;

    public String checkCompletionClass;
    public String callbackClass;

    public Integer staticDelay;
    public IncrementalDelay incremDelay;

    public PollConfiguration withStaticDelay(Integer delay) {
        staticDelay = delay;

        return this;
    }

    public PollConfiguration withIncrementalDelay(IncrementalDelay delay) {
        incremDelay = delay;

        return this;
    }

    public class IncrementalDelay {
        private Integer initialDelay;
        private Integer initialDelayIterations;

        private Integer middleDelay;
        private Integer middleDelayIterations;
        
        private Integer finalDelay;
        private Integer finalDelayIterations;

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

        public IncrementalDelay withFinalIterations(Integer seconds, Integer iterationsCount) {
            finalDelay = seconds;
            finalDelayIterations = iterationsCount;

            return this;
        }
    }


}
