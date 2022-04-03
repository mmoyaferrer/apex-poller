public with sharing class MockCompletionChecker implements Callable {
    public Object call(String action, Map<String,Object> args) {
        Map<String, Object> httpResponse = (Map<String, Object>) args.get('default');
        String status = (String) httpResponse.get('Status');

        return status == 'Completed';
    }
}