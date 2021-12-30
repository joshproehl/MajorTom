defmodule MajorTom.Flherne.Stupid do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias __MODULE__

  schema "stupid" do
    field :msg, :string
    field :submitted_by, :string, default: "unknown"

    timestamps()
  end

  @doc false
  def changeset(stupid, attrs) do
    stupid
    |> cast(attrs, [:msg, :submitted_by])
    |> validate_required([:msg])
    |> unique_constraint(:msg, name: :stupid_msg_unique_index, message: "this quote already exists")
  end

  def search(term) do
    default_query()
    |> where([s], fragment("msg ILIKE ?", ^"%#{term}%"))
  end

  def all(query \\ default_query()), do: query

  def random(query \\ default_query()) do
    query
    |> order_by(fragment("RANDOM()"))
    |> limit(1)
  end

  def after_id(query \\ default_query(), after_id) do
    inner_query = query
      |> where([s], s.id > ^after_id)
      |> order_by([s], [asc: :id])

    from q in subquery(inner_query),
      order_by: [desc: :id]
  end

  def before_id(query \\ default_query(), before_id) do
    inner_query =
      query
      |> where([s], s.id < ^before_id)
  end

  defp default_query() do
    Stupid
    |> order_by([s], [desc: :id])
  end
end
