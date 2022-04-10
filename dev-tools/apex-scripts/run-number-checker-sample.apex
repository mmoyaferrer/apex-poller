PollConfiguration configuration = new PollConfiguration()
    .withPollAction('RequestNumber')
    .withCompletionChecker('NumberChecker')
    .withCallbackAction('CorrectNumberCallback')
    .withTimeout(86400)
    .addDelay(1, 5)
    .addDelay(2, 10)
    .addDelay(3, 30);

new Poller(configuration).execute();

