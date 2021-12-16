defmodule MajorTom.Flherne.Outcome do
  use Ecto.Schema
  import Ecto.Changeset

  schema "outcome" do
    field :msg, :string
    field :submitted_by, :string, default: "unknown"

    timestamps()
  end

  @doc false
  def changeset(outcome, attrs) do
    outcome
    |> cast(attrs, [:msg, :submitted_by])
    |> validate_required([:msg])
    |> unique_constraint(:msg, name: :outcome_msg_unique_index, message: "this is already a potential outcome")
  end
end
