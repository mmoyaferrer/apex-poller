public with sharing class RequestNumber implements Callable {
    public Object call(String action, Map<String, Object> args) {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('http://www.randomnumberapi.com/api/v1.0/random?min=1&max=10');
        HttpResponse response = new Http().send(request);

        return (Object) JSON.deserializeUntyped(response.getBody());
    }
}
