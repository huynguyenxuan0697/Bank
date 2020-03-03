defmodule Hello.Usermanage do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset
  alias Hello.{Usermanage, Repo}

  @psw_secret "sfowieru091203921idsadfijljxzvcz00zaalkNDSADLKS09800DZMXCMkmsfasdfas123131dffd332d+_="

  schema "users" do
    field :account, :string
    field :password, :string
    field :money, :integer
  end

  @doc false
  def changeset(%Usermanage{} = user, params \\ %{}) do
    user
    |> cast(params, [:account, :password, :money])
    |> validate_required([:money])
  end

  def insert_changeset(%Usermanage{} = user, params \\ %{}) do
    user
    |> cast(params, [:account, :password, :money])
    |> validate_required([:account, :password])
    |> validate_length(:password, min: 7)
    |> unique_constraint(:account)
  end

  def money_changeset(%Usermanage{} = user, params \\ %{}) do
    user
    |> cast(params, [:money])
    |> validate_required([:money])
    |> check_constraint(:money, name: :money_must_be_positive)
  end

  def show_id(account) do
    Usermanage
    |> where([u], u.account == ^account)
    |> select([u], u.id)
    |> Repo.one()
  end

  def get_user(id) do
    Usermanage
    |> Repo.get(id)
  end

  def insert_user(account, password) do
    params = %{account: account, password: password}
    insert_changeset = insert_changeset(%Usermanage{}, params)
    Repo.insert(insert_changeset)
  end

  def check_user(account, password) do
    id =
      Usermanage
      |> where([u], u.account == ^account and u.password == ^password)
      |> select([u], u.id)
      |> Repo.one()
  end

  def check_account(account) do
    id =
      Usermanage
      |> where([u], u.account == ^account)
      |> select([u], u.id)
      |> Repo.one()
  end

  def show_money(id) do
    Usermanage
    |> where([u], u.id == ^id)
    |> select([u], u.money)
    |> Repo.one()
  end
  
  def update_money(id, money) do
    params = %{money: money}
    changeset = money_changeset(%Usermanage{id: elem(Integer.parse(id), 0)}, params)
    Repo.update(changeset)
  end
end
