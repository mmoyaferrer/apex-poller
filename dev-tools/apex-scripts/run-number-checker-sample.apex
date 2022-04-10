new Poller(
    new Poller.Configuration()
        .pollWith('RequestNumber')
        .untilTrue('NumberChecker')
        .then('CorrectNumberCallback')
        .timeout(86400)
        .addDelay(1, 5)
        .addDelay(2, 10)
        .addDelay(3, 30)
).execute();

