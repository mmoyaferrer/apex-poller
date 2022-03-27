public with sharing class MockCallback implements PollFinishCallbackI {
    public void execute(Object httpResponse) {
        insert new Account(Name = 'Mock Account');
    }
}