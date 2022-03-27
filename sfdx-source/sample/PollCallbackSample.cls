public with sharing class PollCallbackSample implements PollFinishCallbackI {
    public void execute(Object httpResponse) {
        System.debug('PollCallbackSample');
        insert new Account(Name = 'Test');
    }
}