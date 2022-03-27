public with sharing class PollCompletionCheckerSample implements PollCompletionCheckerI {
    public Boolean execute(Object httpResponse) {
        Account acc = [SELECT Industry FROM Account WHERE Name = 'Sample'];

        return acc.Industry == 'Engineering';
    }
}