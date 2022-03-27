public with sharing class MockCompletionChecker implements PollCompletionCheckerI {
    public Boolean execute(Object httpResponse) {
        Map<String, Object> response = (Map<String, Object>) httpResponse;
        String status = (String) response.get('Status');

        return status == 'Completed';
    }
}