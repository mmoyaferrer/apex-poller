public with sharing class PollConfiguration {    
    public String pollClass {get; private set;}
    public String checkCompletionClass {get; private set;}
    public String callbackClass {get; private set;}
    public Integer staticDelay {get; private set;}
    public List<IncrementalDelay> incremDelay {get; private set;}
    public Datetime startTime{get; private set;}
    public Integer timeout {get; private set;}

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
        if(this.incremDelay == null){
            this.incremDelay = new List<IncrementalDelay>();
         }
        this.incremDelay.add(delay);
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

    public class IncrementalDelay implements Comparable{
        public Integer delayInSeconds;
        public Integer iterationsCount;

        public IncrementalDelay addDelay(Integer delayInSeconds, Integer iterationsCount) {
            this.delayInSeconds = delayInSeconds;
            this.iterationsCount = iterationsCount;
            return this;
        }

        public Integer compareTo(Object compareTo) {
            IncrementalDelay inc = (IncrementalDelay)compareTo;
            if (iterationsCount == inc.iterationsCount) return 0;
            if (iterationsCount > inc.iterationsCount) return 1;
            return -1;   
        }        
    }


}
