defmodule MajorTom.Flherne.Colloid do
  use Ecto.Schema
  import Ecto.Changeset

  schema "colloid" do
    field :msg, :string
    field :submitted_by, :string, default: "unknown"

    timestamps()
  end

  @doc false
  def changeset(colloid, attrs) do
    colloid
    |> cast(attrs, [:msg, :submitted_by])
    |> validate_required([:msg, :submitted_by])
    |> unique_constraint(:msg, name: :colloid_msg_unique_index, message: "this colloid already exists")
  end
end
