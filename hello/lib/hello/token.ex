defmodule Hello.Token do
    use Ecto.Schema
    import Ecto.Query
    import Ecto.Changeset
    alias Hello.{Token, Repo}
    
    @primary_key {:user_id, :integer, []}
    @derive {Phoenix.Param, key: :user_id}
    schema "token" do
        field :token_secret, :string
    end
  
    def changeset(%Token{} = user, params \\ %{}) do
      user
      |> cast(params, [:user_id, :token_secret])
      |> validate_required([:user_id, :token_secret])
    end

    def insert_secret(user_id,token_secret) do
        params= %{user_id: user_id, token_secret: token_secret}
        changeset = changeset(%Token{}, params)
        Repo.insert(changeset)
    end

    def get_secret(user_id)do    
        Token
        |> where([u], u.user_id == ^user_id)
        |> select([u], u.token_secret)
        |> Repo.one()
    end

    def delete_secret(user_id)do
        get = Repo.get!(Token,user_id)
        Repo.delete(get)
    end


end