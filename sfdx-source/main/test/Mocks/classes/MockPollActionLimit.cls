public with sharing class MockPollActionLimit implements Callable {
    public Object call(String action, Map<String, Object> args) {
        if (Test.isRunningTest()) {
            // while (true); Results in limit error, non catcheable exception.
            // Although this is the purpose for real scenarios, in test classes it would cause the test method to fail, so he throw DmlException instead.
            throw new DmlException('Test My Finalizer');
        }

        return true;
    }
}
