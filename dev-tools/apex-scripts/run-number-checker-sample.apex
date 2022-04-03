PollConfiguration configuration = new PollConfiguration()
    .withPollAction('RequestNumber')
    .withCompletionChecker('NumberChecker')
    .withCallbackAction('CorrectNumberCallback')
    .withIncrementalDelay(new PollConfiguration.IncrementalDelay()
                .withInitialIterations(3, 1)
                .withMiddleIterations(10, 2)
                .withFinalIterations(30));

new Poller(configuration).start();

