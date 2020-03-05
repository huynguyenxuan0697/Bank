defmodule HelloWeb.ApiBankController do
  use HelloWeb, :controller
  alias HelloWeb.Router.Helpers
  alias Hello.{Repo, Usermanage, Token, Guardian}
  alias Plug.Crypto.MessageVerifier
  alias HelloWeb.Response
  import Ecto.Query

  # Oauth
  @app_id "197695828014122"
  @app_secret "dd085e5054471410b9fc55fb1fd4de8e"
  @redirect_url "http://localhost:4000/api/bank/FacebookHandler"
  @facebook_api "https://graph.facebook.com"
  # Password secret
  @psw_secret "sfowieru091203921idsadfijljxzvcz00zaalkNDSADLKS09800DZMXCMkmsfasdfas123131dffd332d+_="
  # jwt
  # minute
  @life_time 60

  def show_all(conn, _params) do
    users =
      Repo.all(Usermanage)
      |> Enum.map(fn struct -> struct_to_map(struct) end)

    json(conn, users)
  end

  def create(conn, %{"account" => account, "password" => password}) do
    cond do
      String.match?(password, ~r/^\s*$/) ->
        Response.error(conn, "Password can't be blank")

      !is_nil(password) && String.length(password) < 7 ->
        Response.error(conn, "Password must be longer than 6 characters")

      !is_nil(Usermanage.check_account(account)) ->
        Response.error(conn, "Duplicate account")

      true ->
        password = :crypto.hash(:sha256, password <> @psw_secret) |> Base.url_encode64()

        case Usermanage.insert_user(account, password) do
          {:ok, struct} ->
            resp = %{
              status: "ok"
            }

            conn |> json(resp)

          {:error, changeset} ->
            message = error_parse(changeset.errors)
            Response.error(conn, message)

          _ ->
            Response.error(conn, "Unknown")
        end
    end
  end

  # account, password parse
  defp error_parse(errors) do
    case errors do
      [account: {message, detail}] ->
        "Account #{message}"

      [password: {message, detail}] ->
        "Password #{message}"

      [
        account: {acc_message, acc_detail},
        password: {pass_message, pass_detail}
      ] ->
        "Account #{acc_message}, Password #{pass_message}"

      _ ->
        "Unknown"
    end
  end

  defp money_error_parse(errors) do
    case errors do
      [money: {message, detail}] -> "Money #{message}"
      _ -> "Unknown"
    end
  end

  # Deposit , withdraw, transfer ________________________________________________
  def deposit(conn,   params) do
    if is_nil(params["deposit"]) do
      Response.error(conn,Response.add_message([],"Wrong parameter",400))
    end
    %{"deposit" => deposit} = params
    id = conn.assigns[:id]
    with(
      {:ok, money} <- validate_money(deposit),
      {:ok, money} <- add_money(id, money),
      {:ok, struct} <- Usermanage.update_money(id, money)
    ) do
      Response.ok(conn, %{money: money})
    else
      {:money_error, message} ->
        Response.error(conn, Response.add_message([], message, 400))
      {:error, changeset} ->
        message = money_error_parse(changeset.errors)
        Response.error(conn, Response.add_message([], message, 400))
      {:handle_money_error,message} ->
        Response.error(conn, Response.add_message([], message, 400))
      _ ->
        Response.error(conn, Response.add_message([], "Unknown", 400))
    end
  end

  def withdraw(conn, params) do
    if is_nil(params["withdraw"]) do
      Response.error(conn,Response.add_message([],"Wrong parameter",400))
    end
    %{"withdraw" => withdraw} = params
        
    id = conn.assigns[:id]
    
    with(
      {:ok, money} <- validate_money(withdraw),
      {:ok, money} <- sub_money(id, withdraw),
      {:ok, struct} <- Usermanage.update_money(id, money)
    ) do
      Response.ok(conn, %{money: money})
    else
      {:money_error, message} ->
        Response.error(conn, Response.add_message([], message, 400))

      {:error, changeset} ->
        message = money_error_parse(changeset.errors)
        Response.error(conn, Response.add_message([], message, 400))
      {:handle_money_error,message} ->
        Response.error(conn, Response.add_message([], message, 400))
      _ ->
        Response.error(conn, Response.add_message([], "Unknown", 400))
    end
  end

  def transfer(conn, params) do
    if is_nil(params["receiverid"] && 
        params["receivername"] && 
        params["money"]) do
      Response.error(conn,Response.add_message([],"Wrong parameter",400))
    end
    %{
      "receiverid" => receiverid,
      "receivername" => receivername,
      "money" => money
    } = params
    id = conn.assigns[:id]

    id = conn.assigns[:id]
    error_list = []
    # check receiverid
    error_list = check_receiverid(error_list, receiverid)
    # check receiver name
    error_list = check_receivername(error_list, receivername)
    # check receiver id and name 
    error_list = check_receiver_id_name(error_list, receiverid, receivername)
    # check money
    error_list = check_money(error_list, money)

    if error_list !== [] do
      Response.error(conn, error_list)
    end

    # check schema, sub money        
    with(
      {:ok, target_money} <- add_money(receiverid, money),
      {:ok, source_money} <- sub_money(id, money),
      {:ok, source_struct} <- Usermanage.update_money(id, source_money),
      {:ok, target_struct} <- Usermanage.update_money(receiverid, target_money)
    ) do
      Response.ok(conn, %{money: source_money})
    else
      {:handle_money_error, message} ->
        error_list = Response.add_message(error_list, message, 400)
        Response.error(conn, error_list)

      {:error, changeset} ->
        message = money_error_parse(changeset.errors)
        error_list = Response.add_message(error_list, message, 400)
        Response.error(conn, error_list)

      _ ->
        Response.error(conn, "Unknown")
    end
  end

  defp check_receiverid(error_list, receiverid) do
    cond do
      String.match?(receiverid, ~r/^\s*$/) ->
        error_list = Response.add_message(error_list, "Receiver's id can't be blank", 400)

      !(String.match?(receiverid, ~r/^[0-9]*$/)) ->
        error_list = Response.add_message(error_list, "Receiver's id must be positive number", 400)

      true ->
        error_list
    end
  end

  defp check_receivername(error_list, receivername) do
    cond do
      String.match?(receivername, ~r/^\s*$/) ->
        error_list = Response.add_message(error_list, "Receiver's name can't be blank", 400)
      true ->
        error_list
    end
  end

  defp check_receiver_id_name(error_list, receiverid, receivername) do
    if !String.match?(receiverid, ~r/^\s*$/) 
    && !String.match?(receivername, ~r/^\s*$/) 
    && String.match?(receiverid, ~r/^[0-9]*$/)
    do
      cond do
        String.to_integer(receiverid) !== Usermanage.show_id(receivername) ->
          error_list = Response.add_message(error_list, "Account and id are not matched", 400)

        true ->
          error_list
      end
    else
      error_list
    end
  end

  defp check_money(error_list, money) do
    cond do
      !is_binary(money) -> 
        error_list = Response.add_message(error_list, "Money must be string", 400)
      String.to_integer(money) ->
        error_list = Response.add_message(error_list, "Money can't be greater than 50 mil", 400)
      String.match?(money, ~r/^\s*$/) ->
        error_list = Response.add_message(error_list, "Money can't be blank", 400)

      !String.match?(money, ~r/^[0-9]*$/) ->
        error_list = Response.add_message(error_list, "Money must be positive number", 400)

      true ->
        error_list
    end
  end

  defp validate_money(money)  do
    cond do
      !is_binary(money) -> 
        {:money_error, "Money must be string"}
      String.to_integer(money) > 50000000 ->
        {:money_error, "Money can't greater than 50 mil"}
      String.match?(money, ~r/^\s*$/) -> 
        {:money_error, "Money can't be blank"}
      !String.match?(money, ~r/^[0-9]*$/) -> 
        {:money_error, "Money must be positive number"}
      true -> 
        {:ok, money}
    end
  end

  defp add_money(id, deposit) do
    deposit = String.to_integer(deposit)
    money = Usermanage.show_money(id)
    money = money + deposit
    {:ok, money}
  end

  defp sub_money(id, withdraw) do
    money = Usermanage.show_money(id)
    withdraw = String.to_integer(withdraw)

    cond do 
      withdraw > money ->
      {:handle_money_error, "Money in your account is not enough"}
      true ->
      money = money - withdraw
      {:ok, money}
    
    end
  end

  # _____________________________________________________________________________

  def get_user_info(conn, _params) do
    id = conn.assigns[:id]
    user = Usermanage.get_user(id) |> struct_to_map() |> Map.drop([:password])
    Response.ok(conn, user)
  end

  # Sigin _____________________________________________________________________
  def signin(conn, %{"account" => account, "password" => password}) do
    password = :crypto.hash(:sha256, password <> @psw_secret) |> Base.url_encode64()

    case token_sign_in(account, password) do
      {:ok, token, user_info} ->
        data = %{accesstoken: token}
        Response.ok(conn, data)

      _ ->
        Response.error(conn, "Account or password is not true")
    end
  end

  def token_sign_in(account, password) do
    case verify_account_password(account, password) do
      # {:ok, id} -> Guardian.encode_and_sign(Usermanage.get_user(id),%{}, ttl: {1, :minute})
      {:ok, id} ->
        user_info = Usermanage.get_user(id) |> struct_to_map() |> Map.drop([:password])
        {:ok, jwt_encode(Usermanage.get_user(id)), user_info}

      _ ->
        {:error, :unauthorized}
    end
  end

  def jwt_encode(user) do
    # -------------- header ---------------------
    header = %{
      "alg" => "HS256",
      "typ" => "JWT"
    }

    {:ok, json_header} = JSON.encode(header)
    jwt_header = Base.url_encode64(json_header)
    # -------------- claim -------------------
    time_now = DateTime.utc_now() |> DateTime.to_unix()

    claim = %{
      "exp" => time_now + @life_time * 60,
      "nbf" => time_now - 1,
      "iat" => time_now,
      "sub" => Integer.to_string(user.id),
      "iss" => "bankapi",
      "aud" => "bank_app"
    }

    {:ok, json_claim} = JSON.encode(claim)
    jwt_claim = Base.url_encode64(json_claim)
    # -----------------secret-------------------------
    secret = get_secret(user.id)
    # --------------- signature ---------------------
    signature = jwt_header <> "." <> jwt_claim
    jwt_signature = :crypto.hmac(:sha256, secret, signature) |> Base.url_encode64()
    # ---------------- jwt token ---------------------
    token = jwt_header <> "." <> jwt_claim <> "." <> jwt_signature
    token
  end

  def get_secret(id) do
    secret = Token.get_secret(id)

    if is_nil(secret) do
      secret = :crypto.strong_rand_bytes(60) |> Base.url_encode64()
      Token.insert_secret(id, secret)
      secret
    else
      secret
    end
  end

  # Logout _________________________________________________________________________
  def logout(conn, _params) do
    id = conn.assigns[:id]
    Token.delete_secret(id)

    resp = %{
      status: "ok",
      message: "Log out successfully"
    }

    json(conn, resp)
  end

  # ________________________________________________________________________________
  defp struct_to_map(struct) do
    struct
    |> Map.from_struct()
    |> Map.drop([:__meta__])
  end

  def verify_account_password(account, password) do
    id = Usermanage.check_user(account, password)

    if is_nil(id) do
      {:error, "Account or password not true"}
    else
      {:ok, id}
    end
  end

  def facebook_login(conn, _params) do
    redirect(conn,
      external:
        "https://www.facebook.com/v6.0/dialog/oauth?client_id=#{@app_id}&redirect_uri=#{
          "http://localhost:4000/api"
        }&state=#{"{st=state123abc,ds=123456789}"}&response_type=token"
    )
  end

  # exchange code for access token
  def facebook_login_handler(conn, %{"accesstoken" => access_token}) do
    # %{
    #     "access_token"=> access_token,
    #     "expires_in"=> expires_in,
    #     "token_type" => token_type
    #     } = exchange_access_token(code) # expire : second till expire

    %{
      "app_id" => app_id,
      "type" => type,
      "application" => application,
      "data_access_expires_at" => data_access_expires_at,
      "expires_at" => expires_at,
      "is_valid" => is_valid,
      "scopes" => scope,
      "user_id" => user_id
    } = inspect_access_token(access_token)

    %{
      "email" => email,
      "name" => name
    } = get_username_email(access_token, user_id)

    user = Repo.get_by(Usermanage, account: name)

    if is_nil(user) do
      hashing_password = :crypto.hash(:sha256, user_id <> @psw_secret) |> Base.url_encode64()
      Usermanage.insert_user(name, hashing_password)
    end

    signin(conn, %{"account" => name, "password" => user_id})
  end

  defp exchange_access_token(code) do
    url =
      "#{@facebook_api}/v6.0/oauth/access_token?client_id=#{@app_id}&redirect_uri=#{@redirect_url}&client_secret=#{
        @app_secret
      }&code=#{code}"

    {:ok, resp} = HTTPoison.get(url)
    {:ok, json_resp} = JSON.decode(resp.body)
    json_resp
  end

  defp get_app_access_token() do
    url =
      "#{@facebook_api}/oauth/access_token?client_id=#{@app_id}&client_secret=#{@app_secret}&grant_type=client_credentials"

    {:ok, resp} = HTTPoison.get(url)
    {:ok, json_resp} = JSON.decode(resp.body)
    json_resp["access_token"]
  end

  defp inspect_access_token(access_token) do
    app_access_token = get_app_access_token()

    url =
      "#{@facebook_api}/debug_token?input_token=#{access_token}&access_token=#{app_access_token}"

    {:ok, resp} = HTTPoison.get(url)
    {:ok, json_resp} = JSON.decode(resp.body)
    json_resp["data"]
  end

  defp get_username_email(access_token, user_id) do
    url = "#{@facebook_api}/#{user_id}?fields=name,email&access_token=#{access_token}"
    {:ok, resp} = HTTPoison.get(url)
    {:ok, json_resp} = JSON.decode(resp.body)
    json_resp
  end

  
end