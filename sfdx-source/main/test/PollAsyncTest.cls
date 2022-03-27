@isTest
private class PollAsyncTest {
    @isTest
    private static void execute() {
        // Setup
        PollConfiguration configuration = createPollConfiguration();

        String mockCalloutResponse = '{"Status": "Completed"}';
        Test.setMock(HttpCalloutMock.class, new MockCalloutResponseGenerator().withSuccessfullResponse(mockCalloutResponse));

        // Exercise
        Test.startTest();
        System.enqueueJob(new PollAsync(configuration));
        Test.stopTest();

        // Verify
        System.assertEquals(1, [SELECT Count() FROM Account]);

        Datetime now = Datetime.now();
        System.assertEquals(0, [SELECT Count() FROM CronTrigger WHERE NextFireTime > :now]);
    }

    @isTest
    private static void executeAndReschedule() {
        // Setup
        PollConfiguration configuration = createPollConfiguration();

        String mockCalloutResponse = '{"Status": "In Progress"}';
        Test.setMock(HttpCalloutMock.class, new MockCalloutResponseGenerator().withSuccessfullResponse(mockCalloutResponse));

        // Exercise
        Test.startTest();
        System.enqueueJob(new PollAsync(configuration));
        Test.stopTest();

        // Verify
        System.assertEquals(0, [SELECT Count() FROM Account]);

        Datetime now = Datetime.now();
        System.assertEquals(1, [SELECT Count() FROM CronTrigger WHERE NextFireTime > :now]);
    }

    private static PollConfiguration createPollConfiguration() {
        PollConfiguration result = new PollConfiguration();

        result.endpoint = 'https://mock.com';
        result.method = 'GET';
        result.callbackClass = 'MockCallback';
        result.checkCompletionClass = 'MockCompletionChecker';

        return result;
    }
}
