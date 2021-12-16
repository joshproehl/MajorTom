defmodule MajorTom.Repo.Migrations.CreateColloid do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create table(:colloid) do
      add :msg, :string, null: false
      add :submitted_by, :string

      timestamps()
    end

    create index("colloid", ["(digest(\"msg\", 'sha512'::text))"], unique: true, concurrently: true, name: "colloid_msg_unique_index")
  end
end
