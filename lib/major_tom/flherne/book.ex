defmodule MajorTom.Flherne.Book do
  use Ecto.Schema
  import Ecto.Changeset

  schema "book" do
    field :msg, :string
    field :submitted_by, :string, default: "unknown"

    timestamps()
  end

  @doc false
  def changeset(book, attrs) do
    book
    |> cast(attrs, [:msg, :submitted_by])
    |> validate_required([:msg])
    |> unique_constraint(:msg, name: :book_msg_unique_index, message: "this book is already in the ary")
  end
end
