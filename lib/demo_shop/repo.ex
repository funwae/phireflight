defmodule DemoShop.Repo do
  @moduledoc """
  DemoShop uses the same database as PhireFlight.
  For simplicity, we alias to PhireFlight.Repo.
  """
  defdelegate all(queryable, opts \\ []), to: PhireFlight.Repo
  defdelegate get(queryable, id, opts \\ []), to: PhireFlight.Repo
  defdelegate get!(queryable, id, opts \\ []), to: PhireFlight.Repo
  defdelegate get_by(queryable, clauses, opts \\ []), to: PhireFlight.Repo
  defdelegate insert(struct, opts \\ []), to: PhireFlight.Repo
  defdelegate insert!(struct, opts \\ []), to: PhireFlight.Repo
  defdelegate update(struct, opts \\ []), to: PhireFlight.Repo
  defdelegate update!(struct, opts \\ []), to: PhireFlight.Repo
  defdelegate delete(struct, opts \\ []), to: PhireFlight.Repo
  defdelegate delete!(struct, opts \\ []), to: PhireFlight.Repo
  defdelegate delete_all(queryable, opts \\ []), to: PhireFlight.Repo
  defdelegate preload(structs, preloads, opts \\ []), to: PhireFlight.Repo
  defdelegate transaction(fun_or_multi, opts \\ []), to: PhireFlight.Repo
end

