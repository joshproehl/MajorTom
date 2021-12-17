defmodule MajorTom.Flherne.Bankrupt do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bankrupt" do
    field :msg, :string
    field :submitted_by, :string, default: "unknown"

    timestamps()
  end

  @doc false
  def changeset(bankrupt, attrs) do
    bankrupt
    |> cast(attrs, [:msg, :submitted_by])
    |> validate_required([:msg])
    |> unique_constraint(:msg, name: :bankrupt_msg_unique_index, message: "this bankruptcy is already known")
  end
end
