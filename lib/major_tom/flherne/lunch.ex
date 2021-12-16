defmodule MajorTom.Flherne.Lunch do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lunch" do
    field :msg, :string
    field :submitted_by, :string, default: "unknown"
    field :last_served_at, :utc_datetime
    field :last_served_to, :string

    timestamps()
  end

  @doc false
  def changeset(lunch, attrs) do
    lunch
    |> cast(attrs, [:msg, :submitted_by, :last_served_to, :last_served_at])
    |> validate_required([:msg])
    |> unique_constraint(:msg, name: :lunch_msg_unique_index, message: "this lunch already exists")
  end
end
