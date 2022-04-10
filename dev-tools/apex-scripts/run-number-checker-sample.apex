new Poller(
    new Poller.Configuration()
        .pollWith('RequestNumber')
        .untilTrue('NumberChecker')
        .then('CorrectNumberCallback')
        .addDelay(5, 10)
        .addDelay(10, 20)
        .addDelay(30, 180)
        .timeout(86400)
).execute();