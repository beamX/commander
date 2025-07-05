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

  @doc """
    daemon_sepc = %{
      service_id: %{
        command: "/path/to/executable",
        options: []
      }
    }
  """
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

    processes_to_kill =
      Enum.reduce(running_processes, [], fn process, acc ->
        {id, _pid, _type, _modules} = process

        # id is not in the list of daemons, so we need to kill it
        if Map.get(daemons, id, false) == false do
          [id | acc]
        else
          acc
        end
      end)

    processes_to_start =
      Enum.reduce(daemons, [], fn {id, _}, acc ->
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
    daemon_supervisor_id = to_daemon_supervisor_id(daemon_spec.id)

    {:ok, sup_pid} =
      Supervisor.start_child(
        Commander.Supervisor,
        generate_daemon_supervisor_spec(daemon_supervisor_id)
      )

    Supervisor.start_child(sup_pid, generate_childspec(daemon_spec))
  end

  def stop_process(child_id) do
    daemon_supervisor_id = to_daemon_supervisor_id(child_id)
    Supervisor.terminate_child(daemon_supervisor_id, child_id)
    Supervisor.terminate_child(Commander.Supervisor, daemon_supervisor_id)
    Supervisor.delete_child(Commander.Supervisor, daemon_supervisor_id)
  end

  def get_running_processes do
    Supervisor.which_children(Commander.Supervisor)
    |> Enum.map(fn {id, _, _, _} ->
      Supervisor.which_children(id)
    end)
    |> List.flatten()
  end

  def generate_daemon_supervisor_spec(id) do
    opts = [strategy: :one_for_one, auto_shutdown: :all_significant]

    child_map = %{
      id: id,
      start: {Supervisor, :start_link, [[], opts]}
    }

    Supervisor.child_spec(
      child_map,
      shutdown: 10_000,
      restart: :transient
    )
  end

  @doc """
  Generate worker spec from a configuration list
  """
  def generate_childspec(daemon_spec) do
    child_map = %{
      id: daemon_spec.id,
      start: {:exec, :run_link, [daemon_spec.command, daemon_spec.options]}
    }

    Supervisor.child_spec(
      child_map,
      id: daemon_spec.id,
      shutdown: 10_000,
      # Each daemon is monitored by its own specific supervisor
      # When the process exists we want the supervisor to exit too
      significant: true,
      restart: :transient
    )
  end

  defp to_daemon_supervisor_id(daemon_id) do
    String.to_atom("sup_#{daemon_id}")
  end
end
