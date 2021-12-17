defmodule MajorTom.Repo.Migrations.CreateBankrupt do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create table(:bankrupt) do
      add :msg, :string, null: false
      add :submitted_by, :string

      timestamps()
    end

    create index("bankrupt", ["(digest(\"msg\", 'sha512'::text))"], unique: true, concurrently: true, name: "bankrupt_msg_unique_index")
  end
end
