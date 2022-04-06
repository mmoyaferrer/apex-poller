public with sharing class MockCallback implements Callable {
    public Object call(String action, Map<String, Object> args) {
        insert new Account(Name = 'Mock Account');

        return null;
    }
}
