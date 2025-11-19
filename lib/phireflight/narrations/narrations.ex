defmodule PhireFlight.Narrations do
  @moduledoc """
  The Narrations context manages AI-generated trace explanations.

  Note: LLM integration will be added in Phase 7. For now, this provides
  the basic CRUD operations and a placeholder for generation.
  """

  alias PhireFlight.Narrations.Narration
  alias PhireFlight.Repo
  import Ecto.Query

  @doc """
  Gets the narration for a trace.
  """
  @spec get_narration_by_trace_id(binary()) :: Narration.t() | nil
  def get_narration_by_trace_id(trace_id) do
    Repo.get_by(Narration, trace_id: trace_id)
  end

  @doc """
  Generates a narration for a trace using an LLM.

  Returns `{:ok, narration}` if successful, or `{:error, reason}` if generation fails.

  ## Options

    * `:model` - LLM model to use (default: from config)
    * `:regenerate` - Force regeneration even if narration exists (default: false)

  ## Examples

      iex> generate_for_trace(trace_id)
      {:ok, %Narration{summary: "This trace...", issues: [...]}}

  Note: This is a placeholder implementation. Full LLM integration will be
  implemented in Phase 7.
  """
  @spec generate_for_trace(binary(), keyword()) ::
          {:ok, Narration.t()} | {:error, term()}
  def generate_for_trace(trace_id, opts \\ []) do
    regenerate? = Keyword.get(opts, :regenerate, false)

    case get_narration_by_trace_id(trace_id) do
      nil ->
        # Placeholder: Create a simple narration
        # Full implementation will use LLM in Phase 7
        create_narration(%{
          trace_id: trace_id,
          model_name: "placeholder",
          summary: "Narration generation will be implemented in Phase 7 (AI Narration System).",
          details: "This is a placeholder narration. The full LLM integration will be added in Phase 7.",
          issues: []
        })

      narration when regenerate? ->
        # Regenerate existing narration
        delete_narration(narration)
        generate_for_trace(trace_id, Keyword.put(opts, :regenerate, false))

      narration ->
        {:ok, narration}
    end
  end

  @doc """
  Creates a narration manually.
  """
  @spec create_narration(map()) :: {:ok, Narration.t()} | {:error, Ecto.Changeset.t()}
  def create_narration(attrs \\ %{}) do
    %Narration{}
    |> Narration.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a narration.
  """
  @spec update_narration(Narration.t(), map()) ::
          {:ok, Narration.t()} | {:error, Ecto.Changeset.t()}
  def update_narration(%Narration{} = narration, attrs) do
    narration
    |> Narration.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a narration.
  """
  @spec delete_narration(Narration.t()) ::
          {:ok, Narration.t()} | {:error, Ecto.Changeset.t()}
  def delete_narration(%Narration{} = narration) do
    Repo.delete(narration)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking narration changes.
  """
  @spec change_narration(Narration.t(), map()) :: Ecto.Changeset.t()
  def change_narration(%Narration{} = narration, attrs \\ %{}) do
    Narration.changeset(narration, attrs)
  end
end

