defmodule AppEx.Utils.EctoMultiUtil do
  @moduledoc """
  Ecto.Multi関連の操作機能
  """
  import Ecto.Query, warn: false
  alias Ecto.Multi

  def add_multi_steps(multi, schema, struct, params, space, index \\ 0)
  def add_multi_steps(multi, schema, struct, [], _space, _index ) do
    multi
  end
  def add_multi_steps(multi, schema, struct, params, space, index) do
    {param, next_params} = List.pop_at(params, 0)
    multi = add_multi_step(multi, schema, struct, param, space, index)
    index = index + 1
    add_multi_steps(multi, schema, struct, next_params, space, index)
  end

  defp add_multi_step(multi, schema, struct, params, space, index) do
    change_set = schema.changeset(struct, params)
    source = elem(struct.__meta__.source, 1)
    _multi = Multi.insert(multi, "#{source}_#{index}", change_set, prefix: Triplex.to_prefix(space))
  end

end
