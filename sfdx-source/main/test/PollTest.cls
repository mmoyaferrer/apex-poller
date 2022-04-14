@isTest
private class PollTest {

    @isTest
    private static void execute() {
        // Setup
        new HttpMock()
            .get('', new Response('Completed'))
            .mock();

        // Exercise
        Test.startTest();
            new Poll(new MockPollAction())
                .untilTrue(new MockCompletionChecker())
                .then(new MockCallback())
                .addDelay(1, 5)
                .execute();
        Test.stopTest();

        // Verify
        System.assertEquals(1, [SELECT COUNT() FROM Account]);

        Datetime now = Datetime.now();
        System.assertEquals(0, [SELECT COUNT() FROM CronTrigger WHERE NextFireTime > :now]);
    }

    @isTest
    private static void schedule() {
        // Setup
        new HttpMock()
            .get('', new Response('Completed'))
            .mock();

       Poll testScheduledPoll = new Poll(new MockPollAction())
            .untilTrue(new MockCompletionChecker())
            .then(new MockCallback())
            .addDelay(1, 5);

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
    private static void rescheduleWithStaticDelay() {
        // Setup
        new HttpMock()
            .get('', new Response('In Progress'))
            .mock();

        // Exercise
        Test.startTest();
            new Poll(new MockPollAction())
                .untilTrue(new MockCompletionChecker())
                .then(new MockCallback())
                .staticDelay(100)
                .execute();
        Test.stopTest();

        // Verify
        Datetime now = Datetime.now();
        System.assertEquals(now.addSeconds(100), [SELECT NextFireTime FROM CronTrigger WHERE NextFireTime > :now].NextFireTime);
    }

    @isTest
    private static void rescheduleFirstIterationWithIncrementalPreset() {
        // Setup
        new HttpMock()
            .get('', new Response('In Progress'))
            .mock();

        // Exercise
        Test.startTest();
            new Poll(new MockPollAction())
                .untilTrue(new MockCompletionChecker())
                .then(new MockCallback())
                .incrementalDelaysPreset()
                .execute();
        Test.stopTest();

        // Verify
        Datetime now = Datetime.now();
        System.assertEquals(now.addSeconds(15), [SELECT NextFireTime FROM CronTrigger WHERE NextFireTime > :now].NextFireTime);
    }

    @isTest
    private static void reschedule20IterationWithIncrementalPreset() {
        // Setup
        new HttpMock()
            .get('', new Response('In Progress'))
            .mock();

        Poll polling = new Poll(new MockPollAction())
            .untilTrue(new MockCompletionChecker())
            .then(new MockCallback())
            .incrementalDelaysPreset();

        polling.iteration = 20;

        // Exercise
        Test.startTest();
            polling.execute();
        Test.stopTest();

        // Verify
        Datetime now = Datetime.now();
        System.assertEquals(now.addSeconds(30), [SELECT NextFireTime FROM CronTrigger WHERE NextFireTime > :now].NextFireTime);
    }

    @isTest
    private static void rescheduleFirstIteration() {
        // Setup
        new HttpMock()
            .get('', new Response('In Progress'))
            .mock();

        // Exercise
        Test.startTest();
            new Poll(new MockPollAction())
                .untilTrue(new MockCompletionChecker())
                .then(new MockCallback())
                .addDelay(1, 5)
                .execute();
        Test.stopTest();

        // Verify
        Datetime now = Datetime.now();
        System.assertEquals(now.addSeconds(5), [SELECT NextFireTime FROM CronTrigger WHERE NextFireTime > :now].NextFireTime);
    }

    @isTest
    private static void rescheduleThirdIteration() {
        // Setup
        new HttpMock()
            .get('', new Response('In Progress'))
            .mock();

        Poll polling = new Poll(new MockPollAction())
            .untilTrue(new MockCompletionChecker())
            .then(new MockCallback())
            .addDelay(1, 5)
            .addDelay(3, 15);

        polling.iteration = 3;

        // Exercise
        Test.startTest();
            polling.execute();
        Test.stopTest();

        // Verify
        Datetime now = Datetime.now();
        System.assertEquals(now.addSeconds(15), [SELECT NextFireTime FROM CronTrigger WHERE NextFireTime > :now].NextFireTime);
    }

    @isTest
    private static void rescheduleUnexpectedIterationBeforeTimeout() {
        // Setup
        new HttpMock()
            .get('', new Response('In Progress'))
            .mock();
        
        Poll polling = new Poll(new MockPollAction())
            .untilTrue(new MockCompletionChecker())
            .then(new MockCallback())
            .addDelay(1, 5)
            .addDelay(3, 15)
            .addDelay(15, 30);
        polling.iteration = 100;

        // Exercise
        Test.startTest();
            polling.execute();
        Test.stopTest();

        // Verify
        Datetime now = Datetime.now();
        System.assertEquals(now.addSeconds(30), [SELECT NextFireTime FROM CronTrigger WHERE NextFireTime > :now].NextFireTime);
    }

    @isTest
    private static void rescheduleReachesTimeout() {
        // Setup
        new HttpMock()
            .get('', new Response('In Progress'))
            .mock();

        // Exercise
        Poll.PollingException ex;
        try {
            Test.startTest();
                new Poll(new MockPollAction())
                    .untilTrue(new MockCompletionChecker())
                    .then(new MockCallback())
                    .timeout(0)
                    .addDelay(1, 5)
                    .execute();   
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
        new HttpMock()
            .get('', new Response('Completed'))
            .mock();

        // Exercise
        DmlException ex;
        try {
            Test.startTest();
                new Poll(new MockPollActionLimit())
                    .untilTrue(new MockCompletionChecker())
                    .then(new MockCallback())
                    .addDelay(1, 5)
                    .execute();  
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

    private class Response {
        private String status;

        public Response(String status) {
            this.status = status;
        }
    }
}
