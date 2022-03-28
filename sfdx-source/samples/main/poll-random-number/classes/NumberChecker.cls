public with sharing class NumberChecker implements PollCompletionCheckerI {
    public Boolean execute(Object httpResponse) {
        List<Object> objects = (List<Object>) httpResponse;
        Integer numberFound = (Integer) objects[0];

        System.debug(numberFound);

        return numberFound == 3;
    }
}