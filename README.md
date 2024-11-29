# Commander

Service to run and monitor OS processes.


## Quick example

1. Define a elixir script module `Commander.Daemons` with `get_spec` function which returns processes which should be running,

``` elixir
defmodule Commander.Daemons do
  def get_spec() do
    %{
      sleep: %{
        command: "sleep",
        arg_list: ["500"],
        options: []
      }
    }
  end
end
```

2. Configure the path of the elixir script containing the list of processes to run and monitor

``` elixir
Application.get_env(:commander, :daemons_config_file) # "/home/user/workspace/commander/daemon.exs"
```

3. Lastly invoke `Commander.sync_config()` which will ensure that all processes returned by `Commander.Daemons.get_spec()` are running.
NOTE: Any process which are currently running but no longer returned by `get_spec()` will be stopped.
