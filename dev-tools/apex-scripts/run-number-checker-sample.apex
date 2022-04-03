PollConfiguration configuration = new PollConfiguration();
configuration.pollClass = 'RequestNumber';
configuration.checkCompletionClass = 'NumberChecker';
configuration.callbackClass = 'CorrectNumberCallback';
configuration.incremDelay = new PollConfiguration.IncrementalDelay()
            .withInitialIterations(3, 1)
            .withMiddleIterations(10, 2)
            .withFinalIterations(30);

new Poller(configuration).start();

