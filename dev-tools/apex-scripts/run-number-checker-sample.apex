String method = 'GET';
String endpoint = 'http://www.randomnumberapi.com/api/v1.0/random?min=1&max=10';

PollConfiguration configuration = new PollConfiguration();
configuration.method = method;
configuration.endpoint = endpoint;
configuration.checkCompletionClass = 'NumberChecker';
configuration.callbackClass = 'CorrectNumberCallback';
configuration.incremDelay = new PollConfiguration.IncrementalDelay()
            .withInitialIterations(3, 1)
            .withMiddleIterations(10, 2)
            .withFinalIterations(30);

new Poller(configuration).start();

