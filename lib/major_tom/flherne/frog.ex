defmodule MajorTom.Flherne.Frog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "frog" do
    field :msg, :string
    field :submitted_by, :string, default: "unknown"

    timestamps()
  end

  @doc false
  def changeset(frog, attrs) do
    frog
    |> cast(attrs, [:msg, :submitted_by])
    |> validate_required([:msg])
    |> unique_constraint(:msg, name: :frog_msg_unique_index, message: "this frog already exists")
  end
end
