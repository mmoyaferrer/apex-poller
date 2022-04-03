public with sharing class MockPollAction implements Callable {
    public Object call(String action, Map<String, Object> args) {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('https://mock.com');
        HttpResponse response = new Http().send(request);

        return (Object) JSON.deserializeUntyped(response.getBody());
    }
}
