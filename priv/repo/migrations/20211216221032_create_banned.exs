defmodule MajorTom.Repo.Migrations.CreateBanned do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create table(:banned) do
      add :msg, :string, null: false
      add :submitted_by, :string

      timestamps()
    end

    create index("banned", ["(digest(\"msg\", 'sha512'::text))"], unique: true, concurrently: true, name: "banned_msg_unique_index")
  end
end
