public with sharing class Main {
    public void run() {
        new Poll(new RequestNumber())
            .untilTrue(new NumberChecker())
            .then(new CorrectNumberCallback())
            .incrementalDelaysPreset()
            .execute();
    }
}
