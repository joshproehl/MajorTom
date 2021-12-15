defmodule MajorTom.Repo.Migrations.CreateFrog do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create table(:frog) do
      add :msg, :text, null: false
      add :submitted_by, :string

      timestamps()
    end

    create index("frog", ["(digest(\"msg\", 'sha512'::text))"], unique: true, concurrently: true, name: "frog_msg_unique_index")
  end
end
