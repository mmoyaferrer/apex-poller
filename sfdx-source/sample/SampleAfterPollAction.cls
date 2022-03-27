public with sharing class SampleAfterPollAction implements AfterPollI {
    public void execute(Object httpResponse) {
        System.debug('SampleAfterPollAction');
        insert new Account(Name = 'Test');
    }
}