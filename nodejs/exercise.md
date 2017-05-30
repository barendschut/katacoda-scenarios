Run two services that communicate with each other.

Requirements:

- The first service (named `get-hostname`) returns the HOSTNAME environment variable of the Pod it is running on.
- The service `get-hostname` should not be available outside the cluster.
- The second service (named `use-service`) calls `get-hostname`, reads its response, and returns it.
- There should be at least two replicas of each application.
- `curl host01:30080` should output the result of calling `use-service`

Hints:

- You may use either environment variables or DNS entries to reach a service within the cluster
- The DNS name mapping to a Service's pods is the same as its `metadata.name` value
- 

