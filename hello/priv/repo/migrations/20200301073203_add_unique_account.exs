defmodule Hello.Repo.Migrations.AddUniqueAccount do
  use Ecto.Migration

  def change do
    create unique_index(:users, [:account])
    create constraint("users", :money_must_be_positive, check: "money >= 0")
  end
end
