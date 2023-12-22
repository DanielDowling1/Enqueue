# Enqueue
Bash daemon and agent scripts. Daemon runs with specified level of parallelism and sequentially launches processes that execute tasks assigned to it by enqueue agent. Task processes connect to file-descriptors of agent process so that it functions as though it were executing the task itself.
