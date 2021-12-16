defmodule MajorTom.Repo.Migrations.CreateOutcome do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create table(:outcome) do
      add :msg, :string, null: false
      add :submitted_by, :string

      timestamps()
    end

    create index("outcome", ["(digest(\"msg\", 'sha512'::text))"], unique: true, concurrently: true, name: "outcome_msg_unique_index")
  end
end
