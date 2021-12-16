defmodule MajorTom.Repo.Migrations.CreateLunch do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create table(:lunch) do
      add :msg, :string, null: false
      add :submitted_by, :string
      add :last_served_to, :string
      add :last_served_at, :utc_datetime

      timestamps()
    end

    create index("lunch", ["(digest(\"msg\", 'sha512'::text))"], unique: true, concurrently: true, name: "lunch_msg_unique_index")
  end
end
