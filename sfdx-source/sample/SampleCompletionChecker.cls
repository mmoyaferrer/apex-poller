public with sharing class SampleCompletionChecker implements CheckCompletionI {
    public Boolean execute(Object httpResponse) {
        Account acc = [SELECT Industry FROM Account WHERE Name = 'Sample'];

        return acc.Industry == 'Engineering';
    }
}