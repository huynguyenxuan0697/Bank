defmodule Hello.Repo.Migrations.AddTokenTable do
  use Ecto.Migration

  def change do
    create table(:token, primary_key: false) do
      add :user_id, references("users", column: "id"), primary_key: true
      add :token_secret, :string
    end
  end
end
