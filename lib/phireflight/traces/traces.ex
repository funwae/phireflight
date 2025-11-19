defmodule PhireFlight.Traces do
  @moduledoc """
  The Traces context manages trace recordings (flights).
  """

  alias PhireFlight.Traces.Trace
  alias PhireFlight.TraceEvents.TraceEvent
  alias PhireFlight.Repo
  import Ecto.Query

  @doc """
  Returns the list of recent traces for an app.

  ## Options

    * `:limit` - Maximum number of traces to return (default: 50)
    * `:offset` - Number of traces to skip (default: 0)
    * `:status` - Filter by status (:ok, :error, etc.)

  ## Examples

      iex> list_traces(app_id, limit: 10)
      [%Trace{}, ...]
  """
  @spec list_traces(binary(), keyword()) :: [Trace.t()]
  def list_traces(app_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)
    status = Keyword.get(opts, :status)

    query =
      from t in Trace,
        where: t.app_id == ^app_id,
        order_by: [desc: t.started_at],
        limit: ^limit,
        offset: ^offset

    query =
      if status do
        from t in query, where: t.status == ^status
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Returns all traces (admin function).
  """
  @spec list_all_traces(keyword()) :: [Trace.t()]
  def list_all_traces(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)
    status = Keyword.get(opts, :status)

    query =
      from t in Trace,
        order_by: [desc: t.started_at],
        limit: ^limit,
        offset: ^offset

    query =
      if status do
        from t in query, where: t.status == ^status
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Gets a single trace with preloaded events.
  Raises `Ecto.NoResultsError` if the Trace does not exist.
  """
  @spec get_trace!(binary()) :: Trace.t()
  def get_trace!(id) do
    Repo.get!(Trace, id)
    |> Repo.preload(:trace_events)
  end

  @doc """
  Gets a trace with all events and contexts preloaded.
  """
  @spec get_trace_with_events!(binary()) :: Trace.t()
  def get_trace_with_events!(id) do
    Repo.get!(Trace, id)
    |> Repo.preload([trace_events: :app_context])
  end

  @doc """
  Gets a trace by external ID.
  """
  @spec get_trace_by_external_id(binary(), String.t()) :: Trace.t() | nil
  def get_trace_by_external_id(app_id, external_id) do
    Repo.get_by(Trace, app_id: app_id, external_id: external_id)
  end

  @doc """
  Starts a new trace.

  ## Examples

      iex> start_trace(%{
      ...>   app_id: app_id,
      ...>   entry_point: "GET /checkout",
      ...>   request_method: "GET",
      ...>   request_path: "/checkout",
      ...>   started_at: DateTime.utc_now()
      ...> })
      {:ok, %Trace{}}
  """
  @spec start_trace(map()) :: {:ok, Trace.t()} | {:error, Ecto.Changeset.t()}
  def start_trace(attrs) do
    attrs = Map.put_new(attrs, :started_at, DateTime.utc_now())

    %Trace{}
    |> Trace.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Finishes a trace with final status and timing.

  ## Examples

      iex> finish_trace(trace, %{
      ...>   status: :ok,
      ...>   finished_at: DateTime.utc_now()
      ...> })
      {:ok, %Trace{}}
  """
  @spec finish_trace(Trace.t(), map()) :: {:ok, Trace.t()} | {:error, Ecto.Changeset.t()}
  def finish_trace(%Trace{} = trace, attrs) do
    attrs = Map.put_new(attrs, :finished_at, DateTime.utc_now())

    trace
    |> Trace.finish_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a trace.
  """
  @spec update_trace(Trace.t(), map()) :: {:ok, Trace.t()} | {:error, Ecto.Changeset.t()}
  def update_trace(%Trace{} = trace, attrs) do
    trace
    |> Trace.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a trace and all its events.
  """
  @spec delete_trace(Trace.t()) :: {:ok, Trace.t()} | {:error, Ecto.Changeset.t()}
  def delete_trace(%Trace{} = trace) do
    # Delete all associated events first
    Repo.delete_all(from te in TraceEvent, where: te.trace_id == ^trace.id)
    Repo.delete(trace)
  end

  @doc """
  Returns statistics for an app's traces.

  Returns a map with:
    * :total_count
    * :ok_count
    * :error_count
    * :avg_duration_ms
  """
  @spec get_trace_stats(binary()) :: map()
  def get_trace_stats(app_id) do
    base_query = from t in Trace, where: t.app_id == ^app_id

    total_count = Repo.aggregate(base_query, :count, :id)

    ok_count =
      base_query
      |> where([t], t.status == :ok)
      |> Repo.aggregate(:count, :id)

    error_count =
      base_query
      |> where([t], t.status == :error)
      |> Repo.aggregate(:count, :id)

    avg_duration =
      base_query
      |> where([t], not is_nil(t.duration_ms))
      |> select([t], avg(t.duration_ms))
      |> Repo.one() || 0

    %{
      total_count: total_count,
      ok_count: ok_count,
      error_count: error_count,
      avg_duration_ms: trunc(avg_duration || 0)
    }
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking trace changes.
  """
  @spec change_trace(Trace.t(), map()) :: Ecto.Changeset.t()
  def change_trace(%Trace{} = trace, attrs \\ %{}) do
    Trace.changeset(trace, attrs)
  end
end

