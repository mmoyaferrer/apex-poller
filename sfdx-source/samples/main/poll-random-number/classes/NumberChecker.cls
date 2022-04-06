public with sharing class NumberChecker implements Callable {
    public Object call(String action, Map<String, Object> args) {
        List<Object> httpResponseObjects = (List<Object>) args.get('default');
        Integer numberFound = (Integer) httpResponseObjects[0];

        return numberFound == 3;
    }
}
