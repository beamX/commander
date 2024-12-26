defmodule Commander do
  require Logger

  @doc """
  Sync with daemon config on disk
  """
  def sync_config() do
    Application.get_env(:commander, :daemons_config_file) |> Code.compile_file()

    Commander.Daemons.get_spec()
    |> start_from_config()
  end

  def start_from_config(daemon_spec, dry_run \\ false) do
    daemon_spec
    |> Enum.map(fn {id, spec} -> {id, Map.put(spec, :id, id)} end)
    |> Enum.into(%{})
    |> ensure_all_started(dry_run)
  end

  @doc """
  Ensures that all the daemon from the config are running under the supervisor
  1. Child process currently running under the supervior which are not in daemons list wil be stopped
  2. Child process currently not running under the supervisor will be started
  NOTE: to restart a existing process give it a new id
  """
  def ensure_all_started(daemons, dry_run \\ false) do
    running_processes = get_running_processes()
    running_process_ids = Enum.map(running_processes, fn {id, _, _, _} -> id end)

    processes_to_kill = Enum.reduce(running_processes, [], fn process, acc ->
      {id, _pid, _type, _modules} = process

      # id is not in the list of daemons, so we need to kill it
      if Map.get(daemons, id, false) == false do
        [id | acc]
      else
        acc
      end
    end)

    processes_to_start = Enum.reduce(daemons, [], fn {id, _}, acc ->
      if id not in running_process_ids do
        [id | acc]
      else
        acc
      end
    end)

    Logger.info("Stopping: #{inspect(processes_to_kill)}")
    Logger.info("Starting: #{inspect(processes_to_start)}")

    if not dry_run do
      Enum.map(processes_to_kill, fn id ->
        stop_process(id)
      end)

      Enum.map(processes_to_start, fn id ->
        start_process(Map.get(daemons, id))
      end)
    end
  end

  def start_process(daemon_spec) do
    Supervisor.start_child(Commander.Supervisor, generate_childspec(daemon_spec))
  end

  def stop_process(child_id) do
    Supervisor.terminate_child(Commander.Supervisor, child_id)
    Supervisor.delete_child(Commander.Supervisor, child_id)
  end

  def get_running_processes do
    Supervisor.which_children(Commander.Supervisor)
  end

  @doc """
  Generate worker spec from a configuration list
  """
  def generate_childspec(daemon_spec) do
    Supervisor.child_spec(
      {MuonTrap.Daemon, [daemon_spec.command, daemon_spec.arg_list, daemon_spec.options]},
      id: daemon_spec.id,
      shutdown: 10_000,
      restart: :transient
    )
  end
end
