defmodule HelloWeb.ApiBankController do
    use HelloWeb,:controller
    alias HelloWeb.Router.Helpers
    alias Hello.{Repo,Usermanage,Token,Guardian}
    alias Plug.Crypto.MessageVerifier
    import Ecto.Query

    #Oauth
    @app_id "197695828014122"
    @app_secret "dd085e5054471410b9fc55fb1fd4de8e"
    @redirect_url "http://localhost:4000/api/bank/FacebookHandler"
    @facebook_api "https://graph.facebook.com"
    #Password secret
    @psw_secret "sfowieru091203921idsadfijljxzvcz00zaalkNDSADLKS09800DZMXCMkmsfasdfas123131dffd332d+_="
    #jwt
    @life_time  60   # minute

    
    def show_all(conn, _params) do
        users = Repo.all(Usermanage)
                |> Enum.map(fn struct -> struct_to_map(struct)  end)
        json conn, users
    end
    
    def create(conn, %{"account" => account,"password" => password}) do     
        cond do
        String.match?(password,~r/^\s*$/) ->
            resp_error(conn,"Password can't be blank")
        !is_nil(password) && String.length(password) < 7 -> 
            resp_error(conn,"Password must be longer than 6 characters")
        true ->
        password = :crypto.hash(:sha256, password<>@psw_secret) |> Base.url_encode64()
        case Usermanage.insert_user(account,password) do
            {:ok , struct} ->  
                resp = %{
                    status: "ok"
                }
                conn |> json resp                                
            {:error, changeset} ->  message = error_parse(changeset.errors)
                                    resp_error(conn, message)
                            _   ->  resp_error(conn,"Unknown")
             end            
        end
    end

    defp error_parse(errors) do   #account, password parse
        case errors do
            [account: {message, detail}] ->  "Account #{message}"
            [password: {message,detail}] ->  "Password #{message}"
            [
                account: {acc_message,acc_detail},
                password: {pass_message,pass_detail}
            ]                              
                                -> "Account #{acc_message}, Password #{pass_message}"
                        _       ->           "Unknown"
        end
    end

    defp money_error_parse(errors) do
        case errors do
            [money: {message,detail}] -> "Money #{message}"
                            _         -> "Unknown"
        end
    end

    defp resp_error(conn,message) do
        resp = %{
            status: "error",
            message: message
        }
        conn |> json resp
    end

    defp resp_ok(conn, data ) do
        resp = %{
            status: "ok",
            data: data
        }
        conn |> json resp
    end

    defp add_money(id,deposit) do
        money = Usermanage.show_money(id)
        money = money + elem(Integer.parse(deposit),0)
        {:ok, money}        
    end

    def sub_money(id,withdraw) do
        money    = Usermanage.show_money(id)
        withdraw = elem(Integer.parse(withdraw),0)        
        if (money >= withdraw) do            
            money    = money - withdraw
            {:ok, money}
        else
            {:money_error, "Money in your account is not enough"}
        end
        
    end
   
    defp validate_money(money) when is_binary(money) do
        cond do
        String.match?(money,~r/^\s*$/)      -> {:money_error, "Money can't be blank"}
        !String.match?(money,~r/^[0-9]*$/ ) -> {:money_error, "Money must be positive number"}
                                    true    -> {:ok, money}
        end
    end

    #Deposit , withdraw, transfer ________________________________________________
    def deposit(conn, %{"deposit"=> deposit}) do
        id = conn.assigns[:id]
        with(
            {:ok, money}  <- validate_money(deposit),
            {:ok, money}  <- add_money(id,money),
            {:ok,struct}  <-  Usermanage.update_money(id,money)  
        ) do
            resp_ok(conn, %{money: money})
        else
            {:money_error,message} -> resp_error(conn, message)
                {:error, changeset} ->  message = money_error_parse(changeset.errors)
                                        resp_error(conn, message)
                        _           -> resp_error(conn,"Unknown")
        end                          
    end

    def withdraw(conn, %{"withdraw"=> withdraw}) do
        id = conn.assigns[:id]  
        with(
            {:ok,money} <- validate_money(withdraw),
            {:ok, money} <- sub_money(id,withdraw),
            {:ok , struct} <- Usermanage.update_money(id,money)
        ) do
            resp_ok(conn, %{money: money})
        else
            {:money_error,message} -> resp_error(conn,message)
            {:error, changeset} ->  message = money_error_parse(changeset.errors)
                                        resp_error(conn, message)
                        _           -> resp_error(conn,"Unknown")
        end

    end   

    def transfer(conn,%{"receiverid"=>receiverid,"receivername"=>receivername,"money"=>money}) do
        id = conn.assigns[:id]
        cond do
            String.match?(receiverid ,~r/^\s*$/) -> 
                resp_error(conn,"Receiver id can't be blank")
            String.match?(receivername ,~r/^\s*$/) -> 
                resp_error(conn,"Receiver name can't be blank")            
            !String.match?(receiverid,~r/^[0-9]*$/ ) -> 
                resp_error(conn,"Receiver's id must be number")
            elem(Integer.parse(receiverid),0) !== Usermanage.show_id(receivername) ->
                resp_error(conn,"Account and id are not matched")           
            true    -> 
                with(
                    {:ok, money} <-  validate_money(money),
                    {:ok, target_money} <- add_money(receiverid,money),
                    {:ok, source_money} <- sub_money(id,money),
                    {:ok, source_struct} <- Usermanage.update_money(id, source_money),
                    {:ok, target_struct} <- Usermanage.update_money(receiverid,target_money)
                ) do 
                    resp_ok(conn, %{money: source_money})
                else
                    {:money_error, message} -> resp_error(conn,message)
                    {:error,changeset}   ->     message = money_error_parse(changeset.errors)
                                                resp_error(conn, message)
                                    _ -> resp_error(conn,"Unknown")
                end


                                                                               
        end                     
    end            
    #_____________________________________________________________________________

    def get_user_info(conn,_params) do
        id = conn.assigns[:id]
        user = Usermanage.get_user(id) |> struct_to_map() |> Map.drop([:password]) 
        resp_ok(conn,user)                        
    end
    # Sigin _____________________________________________________________________
    def signin(conn,%{"account"=>account,"password"=>password})  do
        password = :crypto.hash(:sha256, password<>@psw_secret) |> Base.url_encode64()
        case token_sign_in(account,password) do            
                    {:ok, token, user_info}  ->                         
                        data = %{accesstoken: token, account: account}
                        resp_ok(conn, data)
                    _ ->  
                        resp_error(conn,"Account or password is not true")
            end
    end

    def token_sign_in(account,password) do
        case verify_account_password(account,password) do
            # {:ok, id} -> Guardian.encode_and_sign(Usermanage.get_user(id),%{}, ttl: {1, :minute})
            {:ok, id} ->    user_info = Usermanage.get_user(id) |> struct_to_map() |> Map.drop([:password]) 
                            {:ok, jwt_encode(Usermanage.get_user(id)), user_info }
                    _ ->  {:error, :unauthorized}
        end
    end
  
    def jwt_encode(user) do
        # -------------- header ---------------------
        header = %{
            "alg"=>"HS256",
            "typ"=>"JWT"
        }
        {:ok, json_header} = JSON.encode(header)
        jwt_header = Base.url_encode64(json_header)
        # -------------- claim -------------------
        time_now = DateTime.utc_now() |> DateTime.to_unix()
        claim= %{
            "exp"=> time_now + @life_time*60,
            "nbf"=> time_now - 1,
            "iat"=> time_now,
            "sub"=> Integer.to_string(user.id),
            "iss"=>"bankapi",
            "aud"=>"bank_app",
        }
        {:ok, json_claim} = JSON.encode(claim)
        jwt_claim = Base.url_encode64(json_claim)
        #-----------------secret-------------------------
        secret = get_secret(user.id)
        # --------------- signature ---------------------
        signature = jwt_header<>"."<>jwt_claim
        jwt_signature = :crypto.hmac(:sha256, secret, signature) |> Base.url_encode64()
        #---------------- jwt token ---------------------
        token = jwt_header<>"."<>jwt_claim<>"."<>jwt_signature
        token
    end
    
    def get_secret(id) do
        secret = Token.get_secret(id)
        if  is_nil(secret) do
        secret = :crypto.strong_rand_bytes(60) |> Base.url_encode64
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
        resp =%{
            status: "ok",
            message: "Log out successfully"
        }
        json conn,resp
    end 
    #________________________________________________________________________________
    defp struct_to_map(struct) do
        struct
        |> Map.from_struct()
        |> Map.drop([:__meta__])
    end

    def verify_account_password(account,password) do
        id = Usermanage.check_user(account,password)
        if is_nil(id) do
            {:error, "Account or password not true"}
        else
            {:ok, id}
        end
    end    

    def facebook_login(conn,_params) do
        redirect(conn, external: "https://www.facebook.com/v6.0/dialog/oauth?client_id=#{@app_id}&redirect_uri=#{"http://localhost:4000/api"}&state=#{"{st=state123abc,ds=123456789}"}&response_type=token")
    end
    
    def facebook_login_handler(conn, %{"accesstoken"=> access_token}) do #exchange code for access token

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
            "email"=>email,
            "name"=> name
        } = get_username_email(access_token,user_id)

        user = Repo.get_by(Usermanage, account: name)
        if is_nil(user) do
            hashing_password = :crypto.hash(:sha256, user_id<>@psw_secret) |> Base.url_encode64()
            Usermanage.insert_user(name,hashing_password)
        end        
            signin(conn,%{"account"=>name,"password"=>user_id})             
            
    end

    defp exchange_access_token(code)do
        url = "#{@facebook_api}/v6.0/oauth/access_token?client_id=#{@app_id}&redirect_uri=#{@redirect_url}&client_secret=#{@app_secret}&code=#{code}"
        {:ok, resp} = HTTPoison.get(url)
        {:ok, json_resp} = JSON.decode(resp.body)
        json_resp
    end

    defp get_app_access_token() do
        url = "#{@facebook_api}/oauth/access_token?client_id=#{@app_id}&client_secret=#{@app_secret}&grant_type=client_credentials"
        {:ok, resp} = HTTPoison.get(url)
        {:ok, json_resp} = JSON.decode(resp.body)
        json_resp["access_token"]
    end

    defp inspect_access_token(access_token) do
        app_access_token = get_app_access_token()
        url = "#{@facebook_api}/debug_token?input_token=#{access_token}&access_token=#{app_access_token}"
        {:ok, resp} = HTTPoison.get(url)
        {:ok, json_resp} = JSON.decode(resp.body)
         json_resp["data"]
    end
   
    defp get_username_email(access_token,user_id) do
        url = "#{@facebook_api}/#{user_id}?fields=name,email&access_token=#{access_token}"
        {:ok, resp} = HTTPoison.get(url)
        {:ok, json_resp} = JSON.decode(resp.body)
        json_resp
    end

  end

 
