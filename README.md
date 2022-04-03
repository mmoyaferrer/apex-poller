# PleasePoll Framework

## TL;DR

This framework provides a simple and guided way to implement a polling mechanism for long running processes in Salesforce. Appliable to any long-running process, such as Http polling but not limited to it.

## Samples

### Random number checker

A sample of using this framework can be seen in `sfdx-source/samples/main/poll-random-number`. To execute it, a script is provided in `dev-tools/apex-scripts/run-number-checker-sample`

In the sample:
- 1) The polling action requests a random number from www.randomnumberapi.com API
- 2) Check if that number is 3
- 3) Send an email with the information once 3) happens

## Features

- Injection of apex logic by the consumer (through classes names) in order to provide:
    - Polling action
    - Polling status check
    - Polling finisher action
- Static or Incremental delay
    - In case of static delay, specifying it in seconds
    - In case of incremental delay, specifying:
        - Delay (seconds) and number of iteration per each first group of polls and second group of polls
        - Delay (seconds) for rest of polls following first & second group

## How it works?

### TL;DR

This framework makes use of schedulable/queuable apex jobs to:
- Execute the provided polling logic
- Check if the poll has completed
- Re-schedule itself if not completed, by following an injected static/incremental delay pattern.
### Specific details

Given the consumer has initialised a Poll Configuration record, with the following:

- 1) A polling action class, which implements the `Callable` interface, and returns the action response as `Map<String, Object>{'default' => response}`
- 2) A polling status check class, which implements the `Callable` interface, and returns a boolean indicating if the response of 1) is now the final/expected to end the poll, being this boolean wrapped in the callable response `Map<String, Object>{'default' => pollCompleted}`
- 3) A polling finisher action (polling callback), which implements the `Callable` interface, whose logic provides the behaviour to run when the polling has successfully finished
- 4) Static OR Incremental delay
- 5) Polling Timeout seconds

When the consumer start the polling process, by usage of the `Poller` class

Then a queueable apex job will start, and will:
    - Execute the logic provided in the polling action class
    - Check if the response contains the expected data (logic provided in 2)):
        - If yes -> Will call the polling callback and finish the process
        - If no -> Will re-schedule itself following the specified static/incremental delay. For the mentioned re-scheduling, an intermediate schedulable apex class is used.