@isTest
private class PollAsyncTest {
    @isTest
    private static void execute() {
        // Setup
        PollConfiguration configuration = createPollConfiguration();

        String mockCalloutResponse = '{"Status": "Completed"}';
        Test.setMock(
            HttpCalloutMock.class,
            new MockCalloutResponseGenerator().withSuccessfullResponse(mockCalloutResponse)
        );

        // Exercise
        Test.startTest();
        System.enqueueJob(new PollAsync(configuration, 1));
        Test.stopTest();

        // Verify
        System.assertEquals(1, [SELECT COUNT() FROM Account]);

        Datetime now = Datetime.now();
        System.assertEquals(0, [SELECT COUNT() FROM CronTrigger WHERE NextFireTime > :now]);
    }

    @isTest
    private static void executeAndReschedule() {
        // Setup
        PollConfiguration configuration = createPollConfiguration();

        String mockCalloutResponse = '{"Status": "In Progress"}';
        Test.setMock(
            HttpCalloutMock.class,
            new MockCalloutResponseGenerator().withSuccessfullResponse(mockCalloutResponse)
        );

        // Exercise
        Test.startTest();
        System.enqueueJob(new PollAsync(configuration, 1));
        Test.stopTest();

        // Verify
        System.assertEquals(0, [SELECT COUNT() FROM Account]);

        Datetime now = Datetime.now();
        System.assertEquals(1, [SELECT COUNT() FROM CronTrigger WHERE NextFireTime > :now]);
    }

    @isTest
    private static void rescheduleReachesTimeout() {
        // Setup
        PollConfiguration configuration = createPollConfiguration().withTimeout(0);

        String mockCalloutResponse = '{"Status": "In Progress"}';
        Test.setMock(
            HttpCalloutMock.class,
            new MockCalloutResponseGenerator().withSuccessfullResponse(mockCalloutResponse)
        );

        // Exercise
        PollException ex;
        try {
            Test.startTest();
            System.enqueueJob(new PollAsync(configuration, 1));
            Test.stopTest();
        } catch (PollException e) {
            ex = e;
        }

        // Verify
        System.assertEquals('Polling timeout reached', ex.getMessage());
    }

    @isTest
    private static void executeHitsLimitsAndReschedule() {
        // Setup
        PollConfiguration configuration = createPollConfigurationForException();

        String mockCalloutResponse = '{"Status": "Completed"}';
        Test.setMock(
            HttpCalloutMock.class,
            new MockCalloutResponseGenerator().withSuccessfullResponse(mockCalloutResponse)
        );

        // Exercise
        DmlException ex;
        try {
            Test.startTest();
            System.enqueueJob(new PollAsync(configuration, 1));
            Test.stopTest();
        } catch (DmlException e) {
            ex = e;
        }

        // Verify
        System.assertEquals('Test My Finalizer', ex.getMessage());

        System.assertEquals(0, [SELECT COUNT() FROM Account]);

        Datetime now = Datetime.now();
        System.assertEquals(1, [SELECT COUNT() FROM CronTrigger WHERE NextFireTime > :now]);
    }

    private static PollConfiguration createPollConfiguration() {
        return new PollConfiguration()
            .withPollAction('MockPollAction')
            .withCompletionChecker('MockCompletionChecker')
            .withCallbackAction('MockCallback')
            .withStartTime(Datetime.now())
            .withTimeout(86400)
            .withIncrementalDelay(
                new PollConfiguration.IncrementalDelay().addDelay(1, 5).addDelay(3, 15).addDelay(5, 25).addDelay(15, 30)
            );
    }

    private static PollConfiguration createPollConfigurationForException() {
        return new PollConfiguration()
            .withPollAction('MockPollActionLimit')
            .withCompletionChecker('MockCompletionChecker')
            .withCallbackAction('MockCallback')
            .withStartTime(Datetime.now())
            .withTimeout(86400)
            .withIncrementalDelay(
                new PollConfiguration.IncrementalDelay().addDelay(1, 5).addDelay(3, 15).addDelay(5, 25).addDelay(15, 30)
            );
    }
}
