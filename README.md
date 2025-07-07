# Commander

Service to run and monitor OS processes.


## Quick example

1. Define a map which contains all processes which should be running,

``` elixir
daemons = %{
  custom_service: %{
    command: "customer_service start",
    options: []
  },
  haproxy: %{
    command: "haproxy -f /home/user/haproxy/haproxy.cfg -p /home/user/haproxy/run/haproxy.pid",
    options: []
  }
}
```

NOTE: Ensure that the commands are avaiable to user under which the `commander`
service is running

2. Start the services using the following command

``` elixir
Commander.start_from_config(daemons)
```

## Intent

`commander` service is intended to be used in with
[control-node](https://github.com/beamX/control-node) i.e. `control-node`
library enables building a custom orchestrator which can deploy elixir services.
`commander` is an elixir service which runs and manages non elixir processes. So,
`control-node` in conjunction with `commander` can run and manage elixir and
non-elixir services across a fleet of servers.
