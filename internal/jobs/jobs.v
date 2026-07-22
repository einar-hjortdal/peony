module jobs

// WIP
// reliable fifo queue with redict list https://redict.io/docs/commands/lmove/#pattern-reliable-queue
// need a stable identifier for each worker, in order to allow the worker to retrieve its processing queue on recovery.
// many programs that implement such pattern are architectured to have a manager process, this process detects which worker is stuck or dead and re-assigns work to a live worker. This is too much complexity for me right now. I want a stable identifier that can be programmatically selected, possibly a luuid. If the worker runs in an ephemeral container, the file system is recreated at every startup so it cannot be used to persist the identifier. The default hostname for docker container is the container id, which is also ephemeral.
// Either use heartbeat pattern or give up and use user-provided id in config.

// Otherwise use different pattern with redict streams and consumer groups. Which is probably better.
