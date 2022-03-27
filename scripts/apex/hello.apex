// Request
// HttpRequest request = new HttpRequest();
// request.setMethod('GET');
// request.setEndpoint('https://api.nasa.gov/planetary/apod?api_key=zJjSDvbtn2wDdkDaXoCOUJqEFl1RiXDCdscfN89d');
// HttpResponse response = new Http().send(request);
// System.debug(response.getBody());

String method = 'GET';
String endpoint = 'https://api.nasa.gov/planetary/apod?api_key=zJjSDvbtn2wDdkDaXoCOUJqEFl1RiXDCdscfN89d';

PollingParameters parameters = new PollingParameters();
parameters.method = method;
parameters.endpoint = endpoint;
parameters.checkCompletionClass = 'SampleCompletionChecker';
parameters.callbackClass = 'SampleAfterPollAction';

System.enqueueJob(new PleasePoll(parameters));



