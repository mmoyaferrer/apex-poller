@isTest
private class PollerTest {
    @isTest
    private static void start() {
        // Setup
        Poller.Configuration configuration = createPollConfiguration();

        String mockCalloutResponse = '{"Status": "Completed"}';
        Test.setMock(
            HttpCalloutMock.class,
            new MockCalloutResponseGenerator().withSuccessfullResponse(mockCalloutResponse)
        );

        // Exercise
        new Poller(configuration).execute();

        // Verify
        System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob]);
    }

    @isTest
    private static void schedule() {
        // Setup
        Poller.Configuration configuration = createPollConfiguration();

        String mockCalloutResponse = '{"Status": "Completed"}';
        Test.setMock(
            HttpCalloutMock.class,
            new MockCalloutResponseGenerator().withSuccessfullResponse(mockCalloutResponse)
        );

        Poller testScheduledPoll = new Poller(configuration);

        // Note: Because this is a test, job executes immediately after Test.stopTest()
        String nextFireTime = '0 0 0 15 3 ? 2099';

        // Exercise
        Test.startTest();
        System.schedule('Polling - ' + nextFireTime, nextFireTime, testScheduledPoll);
        Test.stopTest();

        // Verify
        System.assertEquals(2, [SELECT COUNT() FROM AsyncApexJob]);
    }

    private static Poller.Configuration createPollConfiguration() {
        return new Poller.Configuration()
            .pollWith('MockPollAction')
            .untilTrue('MockCompletionChecker')
            .then('MockCallback')
            .timeout(86400)
            .addDelay(1, 5)
            .addDelay(3, 15)
            .addDelay(5, 35);
    }
}
