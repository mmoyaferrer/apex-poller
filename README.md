# Apex Poller Framework

## TL;DR

This framework provides a simple and guided way to implement a polling mechanism for long running processes in Salesforce. Applicable to any long-running process, such as Http polling but not limited to it.

## Samples

### Random number checker

A sample of usage of this framework can be found in `sfdx-source/samples/main/poll-random-number`. To execute it, a script is provided [here](dev-tools/apex-scripts/run-number-checker-sample.apex).

In the sample:

-   1. The polling action requests a random number from www.randomnumberapi.com API
-   2. Check if that number is 3
-   3. Send an email with the information once 2) happens

## Features

-   Injection of apex logic by the consumer (through class name) in order to provide:
    -   Polling action
    -   Polling status check
    -   Polling finisher action, also referred as Polling Callback.
-   Specification of Static or Incremental delay
    -   In case of static delay, nº of seconds
    -   In case of incremental delay, specifying:
        -   Nº seconds & number of iterations per each first group of polls and second group of polls
        -   Nº seconds for rest of polls following first & second group

## How does it work?

This framework makes use of schedulable/queuable apex jobs to:

-   Execute the provided polling logic
-   Check if the poll has completed
-   Re-schedule itself if not completed, by following an injected static/incremental delay pattern.

## How to use it?

**Given** the consumer has initialised a Poll Configuration record, with the following apex classes which implement the [`Callable` interface](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_interface_System_Callable.htm):

-   1. A polling action class, which returns a response as `Map<String, Object>{'default' => response}`
-   2. A polling status check class, which returns a boolean indicating if the response of 1) is now the final/expected to end the poll OR not, being this boolean wrapped in the callable response as `Map<String, Object>{'default' => pollCompleted}`
-   3. A polling finisher action (polling callback), which provides the logic to be executed once the polling has successfully finished

**Given** the consumer has specified the following in the Poll Configuration record:

-   4. Static OR Incremental delay
-   5. Polling Timeout seconds

**When** the consumer start the polling process, by usage of the `Poller` class

**Then** a queueable apex job will start, and will:

-   1. Execute the logic provided in the polling action class
-   2. Check if the response contains the expected data, by the logic provided in 1), and:
    -   a) If yes, it will call the polling callback and finish the process
    -   b) If no, it will re-schedule itself following the specified static/incremental delay. For the mentioned re-scheduling, an intermediate schedulable apex class is used.
