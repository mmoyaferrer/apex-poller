// #1 - With Incremental Delays Preset
new Poll(new RequestNumber())
    .untilTrue(new NumberChecker())
    .then(new CorrectNumberCallback())
    .incrementalDelaysPreset()
    .execute();

// #2 - With Custom Incremental Delays
new Poll(new RequestNumber())
    .untilTrue(new NumberChecker())
    .then(new CorrectNumberCallback())
    .addDelay(1, 10)
    .addDelay(5, 20)
    .addDelay(30, 180)
    .execute();

// #3 - With Static Delay
new Poll(new RequestNumber())
    .untilTrue(new NumberChecker())
    .then(new CorrectNumberCallback())
    .staticDelay(15)
    .execute();