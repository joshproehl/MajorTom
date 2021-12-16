defmodule MajorTom.Flherne.Banned do
  use Ecto.Schema
  import Ecto.Changeset

  schema "banned" do
    field :msg, :string
    field :submitted_by, :string, default: "unknown"

    timestamps()
  end

  @doc false
  def changeset(banned, attrs) do
    banned
    |> cast(attrs, [:msg, :submitted_by])
    |> validate_required([:msg])
    |> unique_constraint(:msg, name: :banned_msg_unique_index, message: "this user is already banned")
  end
end
