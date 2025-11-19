defmodule PhireFlight.TraceEvents do
  @moduledoc """
  The TraceEvents context manages individual steps within traces.
  """

  alias PhireFlight.TraceEvents.TraceEvent
  alias PhireFlight.Contexts.AppContext
  alias PhireFlight.Repo
  import Ecto.Query

  @doc """
  Returns the list of events for a trace, ordered by sequence_index.

  ## Examples

      iex> list_trace_events(trace_id)
      [%TraceEvent{}, ...]
  """
  @spec list_trace_events(binary()) :: [TraceEvent.t()]
  def list_trace_events(trace_id) do
    Repo.all(
      from te in TraceEvent,
        where: te.trace_id == ^trace_id,
        order_by: [asc: te.sequence_index],
        preload: :app_context
    )
  end

  @doc """
  Gets a single trace event.

  Raises `Ecto.NoResultsError` if the TraceEvent does not exist.
  """
  @spec get_trace_event!(binary()) :: TraceEvent.t()
  def get_trace_event!(id), do: Repo.get!(TraceEvent, id) |> Repo.preload(:app_context)

  @doc """
  Records a new trace event.

  Automatically increments sequence_index if not provided.

  ## Examples

      iex> record_event(%{
      ...>   trace_id: trace_id,
      ...>   module: "DemoShop.Accounts",
      ...>   function: "create_user",
      ...>   event_type: :context_call,
      ...>   started_at: DateTime.utc_now()
      ...> })
      {:ok, %TraceEvent{}}
  """
  @spec record_event(map()) :: {:ok, TraceEvent.t()} | {:error, Ecto.Changeset.t()}
  def record_event(attrs) do
    attrs =
      attrs
      |> Map.put_new(:started_at, DateTime.utc_now())
      |> Map.put_new_lazy(:sequence_index, fn -> get_next_sequence_index(attrs[:trace_id]) end)

    %TraceEvent{}
    |> TraceEvent.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Records multiple events in a batch.
  """
  @spec record_events([map()]) :: {:ok, [TraceEvent.t()]} | {:error, term()}
  def record_events(events_attrs) when is_list(events_attrs) do
    Repo.transaction(fn ->
      Enum.map(events_attrs, fn attrs ->
        case record_event(attrs) do
          {:ok, event} -> event
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end)
    end)
  end

  @doc """
  Updates a trace event (e.g., to set finished_at and duration).
  """
  @spec update_trace_event(TraceEvent.t(), map()) ::
          {:ok, TraceEvent.t()} | {:error, Ecto.Changeset.t()}
  def update_trace_event(%TraceEvent{} = event, attrs) do
    attrs = maybe_calculate_duration(event, attrs)

    event
    |> TraceEvent.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets the context flow for a trace (ordered unique contexts touched).

  Returns a list of {context, event_count} tuples.
  """
  @spec get_context_flow(binary()) :: [{AppContext.t(), integer()}]
  def get_context_flow(trace_id) do
    Repo.all(
      from te in TraceEvent,
        where: te.trace_id == ^trace_id,
        where: not is_nil(te.app_context_id),
        join: ac in AppContext,
        on: te.app_context_id == ac.id,
        group_by: ac.id,
        select: {ac, count(te.id)},
        order_by: [min(te.sequence_index)]
    )
  end

  @doc """
  Gets context transitions (edges) for a trace.

  Returns a list of {from_context, to_context, count} tuples.
  """
  @spec get_context_transitions(binary()) ::
          [{AppContext.t() | nil, AppContext.t() | nil, integer()}]
  def get_context_transitions(trace_id) do
    events =
      Repo.all(
        from te in TraceEvent,
          where: te.trace_id == ^trace_id,
          order_by: [asc: te.sequence_index],
          preload: :app_context
      )

    transitions =
      events
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [from, to] -> {from.app_context, to.app_context} end)

    transitions
    |> Enum.group_by(& &1)
    |> Enum.map(fn {transition, occurrences} ->
      {elem(transition, 0), elem(transition, 1), length(occurrences)}
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking trace event changes.
  """
  @spec change_trace_event(TraceEvent.t(), map()) :: Ecto.Changeset.t()
  def change_trace_event(%TraceEvent{} = event, attrs \\ %{}) do
    TraceEvent.changeset(event, attrs)
  end

  # Private helpers

  defp get_next_sequence_index(trace_id) when is_binary(trace_id) do
    max_index =
      Repo.one(
        from te in TraceEvent,
          where: te.trace_id == ^trace_id,
          select: max(te.sequence_index)
      ) || -1

    max_index + 1
  end

  defp get_next_sequence_index(_), do: 0

  defp maybe_calculate_duration(event, attrs) do
    started = event.started_at || attrs[:started_at]
    finished = attrs[:finished_at]

    if started && finished do
      duration = DateTime.diff(finished, started, :millisecond)
      Map.put(attrs, :duration_ms, duration)
    else
      attrs
    end
  end
end

