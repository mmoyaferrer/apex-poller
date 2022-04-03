PollConfiguration configuration = new PollConfiguration()
    .withPollAction('RequestNumber')
    .withCompletionChecker('NumberChecker')
    .withCallbackAction('CorrectNumberCallback')
    .withTimeout(86400)
    .withIncrementalDelay(new PollConfiguration.IncrementalDelay()
        .withInitialIterations(10, 1)
        .withMiddleIterations(30, 2)
        .withFinalIterations(60));

new Poller(configuration).execute();