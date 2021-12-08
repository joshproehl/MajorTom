defmodule MajorTom.Flherne.Stupid do
  use Ecto.Schema
  import Ecto.Changeset

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
end
