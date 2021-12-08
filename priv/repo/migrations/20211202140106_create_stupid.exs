defmodule MajorTom.Repo.Migrations.CreateStupid do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS pgcrypto",
            "")

    create table(:stupid) do
      add :msg, :text, null: false
      add :submitted_by, :string

      timestamps()
    end

    create index("stupid", ["(digest(\"msg\", 'sha512'::text))"], unique: true, concurrently: true, name: "stupid_msg_unique_index")
  end
end
