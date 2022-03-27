String method = 'GET';
String endpoint = 'https://api.nasa.gov/planetary/apod?api_key=zJjSDvbtn2wDdkDaXoCOUJqEFl1RiXDCdscfN89d';

PollConfiguration configuration = new PollConfiguration();
configuration.method = method;
configuration.endpoint = endpoint;
configuration.checkCompletionClass = 'PollCompletionCheckerSample';
configuration.callbackClass = 'PollCallbackSample';

new Poller(configuration).start();



