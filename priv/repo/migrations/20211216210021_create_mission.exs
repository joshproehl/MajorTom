defmodule MajorTom.Repo.Migrations.CreateMission do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create table(:mission) do
      add :msg, :string, null: false
      add :submitted_by, :string

      timestamps()
    end

    create index("mission", ["(digest(\"msg\", 'sha512'::text))"], unique: true, concurrently: true, name: "mission_msg_unique_index")
  end
end
