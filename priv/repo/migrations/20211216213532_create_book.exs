defmodule MajorTom.Repo.Migrations.CreateBook do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create table(:book) do
      add :msg, :string
      add :submitted_by, :string

      timestamps()
    end

    create index("book", ["(digest(\"msg\", 'sha512'::text))"], unique: true, concurrently: true, name: "book_msg_unique_index")
  end
end
