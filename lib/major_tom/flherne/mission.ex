defmodule MajorTom.Flherne.Mission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mission" do
    field :msg, :string
    field :submitted_by, :string, default: "unknown"

    timestamps()
  end

  @doc false
  def changeset(mission, attrs) do
    mission
    |> cast(attrs, [:msg, :submitted_by])
    |> validate_required([:msg])
    |> unique_constraint(:msg, name: :mission_msg_unique_index, message: "this is already a mission")
  end
end
