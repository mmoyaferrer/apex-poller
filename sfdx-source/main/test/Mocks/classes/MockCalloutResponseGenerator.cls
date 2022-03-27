
@isTest
public class MockCalloutResponseGenerator implements HttpCalloutMock {
    
    private String responseBody;
    private Integer statusCode;

    public MockCalloutResponseGenerator withSuccessfullResponse(String json) {
        statusCode = 200;
        responseBody = json;

        return this;
    }

    public HTTPResponse respond(HTTPRequest req) {        
        HttpResponse res = new HttpResponse();

        res.setHeader('Content-Type', 'application/json');
        res.setBody(responseBody);
        res.setStatusCode(statusCode);

        return res;
    }
}