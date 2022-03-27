public with sharing class SampleCompletionChecker implements CheckCompletionI {
    public Boolean execute(Object httpResponse) {
        Account acc = [SELECT Done__c FROM Account WHERE Name = 'Sample'];

        return acc.Done__c;
    }
}