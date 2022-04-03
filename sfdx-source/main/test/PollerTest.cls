@isTest
private class PollerTest {
    @isTest
    private static void start() {
        // Setup
        PollConfiguration configuration = createPollConfiguration();

        String mockCalloutResponse = '{"Status": "Completed"}';
        Test.setMock(HttpCalloutMock.class, new MockCalloutResponseGenerator().withSuccessfullResponse(mockCalloutResponse));

        // Exercise
        new Poller(configuration).execute();

        // Verify
        System.assertEquals(1, [SELECT Count() FROM AsyncApexJob]);
    }

    @isTest
    private static void schedule() {
        // Setup
        PollConfiguration configuration = createPollConfiguration();

        String mockCalloutResponse = '{"Status": "Completed"}';
        Test.setMock(HttpCalloutMock.class, new MockCalloutResponseGenerator().withSuccessfullResponse(mockCalloutResponse));

        Poller testScheduledPoll = new Poller(configuration);

        // Note: Because this is a test, job executes immediately after Test.stopTest()
        String nextFireTime = '0 0 0 15 3 ? 2099';

        // Exercise
        Test.startTest();
        System.schedule('Polling - ' + nextFireTime, nextFireTime, testScheduledPoll);
        Test.stopTest();

        // Verify
        System.assertEquals(2, [SELECT Count() FROM AsyncApexJob]);
    }

    private static PollConfiguration createPollConfiguration() {
        return new PollConfiguration()
            .withPollAction('MockPollAction')
            .withCompletionChecker('MockCompletionChecker')
            .withCallbackAction('MockCallback')
            .withIncrementalDelay(new PollConfiguration.IncrementalDelay()
                .withInitialIterations(1, 1)
                .withMiddleIterations(5, 1)
                .withFinalIterations(10));
    }
}
