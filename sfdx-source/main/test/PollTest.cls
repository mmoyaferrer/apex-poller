@isTest
private class PollTest {
    @isTest
    private static void execute() {
        // Setup
        Poll.Configuration configuration = createPollConfiguration();

        String mockCalloutResponse = '{"Status": "Completed"}';
        Test.setMock(
            HttpCalloutMock.class,
            new MockCalloutResponseGenerator().withSuccessfullResponse(mockCalloutResponse)
        );

        // Exercise
        Test.startTest();
        new Poll(configuration).execute();
        Test.stopTest();

        // Verify
        System.assertEquals(1, [SELECT COUNT() FROM Account]);

        Datetime now = Datetime.now();
        System.assertEquals(0, [SELECT COUNT() FROM CronTrigger WHERE NextFireTime > :now]);
    }

    @isTest
    private static void schedule() {
        // Setup
        Poll.Configuration configuration = createPollConfiguration();

        String mockCalloutResponse = '{"Status": "Completed"}';
        Test.setMock(
            HttpCalloutMock.class,
            new MockCalloutResponseGenerator().withSuccessfullResponse(mockCalloutResponse)
        );

        Poll testScheduledPoll = new Poll(configuration);

        // Note: Because this is a test, job executes immediately after Test.stopTest()
        String nextFireTime = '0 0 0 15 3 ? 2099';

        // Exercise
        Test.startTest();
        System.schedule('Polling - ' + nextFireTime, nextFireTime, testScheduledPoll);
        Test.stopTest();

        // Verify
        System.assertEquals(2, [SELECT COUNT() FROM AsyncApexJob]);
    }

    @isTest
    private static void rescheduleFirstIteration() {
        // Setup
        Poll.Configuration configuration = createPollConfiguration();

        String mockCalloutResponse = '{"Status": "In Progress"}';
        Test.setMock(
            HttpCalloutMock.class,
            new MockCalloutResponseGenerator().withSuccessfullResponse(mockCalloutResponse)
        );

        // Exercise
        Test.startTest();
        System.enqueueJob(new Poll.PollAsync(configuration, 1));
        Test.stopTest();

        // Verify
        Datetime now = Datetime.now();
        System.assertEquals(now.addSeconds(5), [SELECT NextFireTime FROM CronTrigger WHERE NextFireTime > :now].NextFireTime);
    }

    @isTest
    private static void rescheduleThirdIteration() {
        // Setup
        Poll.Configuration configuration = createPollConfiguration();

        String mockCalloutResponse = '{"Status": "In Progress"}';
        Test.setMock(
            HttpCalloutMock.class,
            new MockCalloutResponseGenerator().withSuccessfullResponse(mockCalloutResponse)
        );

        // Exercise
        Test.startTest();
        System.enqueueJob(new Poll.PollAsync(configuration, 3));
        Test.stopTest();

        // Verify
        Datetime now = Datetime.now();
        System.assertEquals(now.addSeconds(15), [SELECT NextFireTime FROM CronTrigger WHERE NextFireTime > :now].NextFireTime);
    }

    @isTest
    private static void rescheduleUnexpectedIterationBeforeTimeout() {
        // Setup
        Poll.Configuration configuration = createPollConfiguration();

        String mockCalloutResponse = '{"Status": "In Progress"}';
        Test.setMock(
            HttpCalloutMock.class,
            new MockCalloutResponseGenerator().withSuccessfullResponse(mockCalloutResponse)
        );

        // Exercise
        Test.startTest();
        System.enqueueJob(new Poll.PollAsync(configuration, 100));
        Test.stopTest();

        // Verify
        Datetime now = Datetime.now();
        System.assertEquals(now.addSeconds(30), [SELECT NextFireTime FROM CronTrigger WHERE NextFireTime > :now].NextFireTime);
    }

    @isTest
    private static void rescheduleReachesTimeout() {
        // Setup
        Poll.Configuration configuration = createPollConfiguration().timeout(0);

        String mockCalloutResponse = '{"Status": "In Progress"}';
        Test.setMock(
            HttpCalloutMock.class,
            new MockCalloutResponseGenerator().withSuccessfullResponse(mockCalloutResponse)
        );

        // Exercise
        Poll.PollingException ex;
        try {
            Test.startTest();
            System.enqueueJob(new Poll.PollAsync(configuration, 1));
            Test.stopTest();
        } catch (Poll.PollingException e) {
            ex = e;
        }

        // Verify
        System.assertEquals('Polling timeout reached', ex.getMessage());
    }

    @isTest
    private static void executeHitsLimitsAndReschedule() {
        // Setup
        Poll.Configuration configuration = createPollConfigurationForException();

        String mockCalloutResponse = '{"Status": "Completed"}';
        Test.setMock(
            HttpCalloutMock.class,
            new MockCalloutResponseGenerator().withSuccessfullResponse(mockCalloutResponse)
        );

        // Exercise
        DmlException ex;
        try {
            Test.startTest();
            System.enqueueJob(new Poll.PollAsync(configuration, 1));
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

    private static Poll.Configuration createPollConfiguration() {
        return new Poll.Configuration()
            .pollWith('MockPollAction')
            .untilTrue('MockCompletionChecker')
            .then('MockCallback')
            .beginning(Datetime.now())
            .timeout(86400)
            .addDelay(1, 5)
            .addDelay(3, 15)
            .addDelay(5, 25)
            .addDelay(15, 30);
    }

    private static Poll.Configuration createPollConfigurationForException() {
        return new Poll.Configuration()
            .pollWith('MockPollActionLimit')
            .untilTrue('MockCompletionChecker')
            .then('MockCallback')
            .beginning(Datetime.now())
            .timeout(86400)
            .addDelay(1, 5)
            .addDelay(3, 15)
            .addDelay(5, 25)
            .addDelay(15, 30);
    }
}
