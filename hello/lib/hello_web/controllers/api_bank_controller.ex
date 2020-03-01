defmodule HelloWeb.ApiBankController do
    use HelloWeb,:controller
    alias HelloWeb.Router.Helpers
    alias Hello.{Repo,Usermanage,Guardian}
    alias Plug.Crypto.MessageVerifier
    import Ecto.Query

    

    def show_all(conn, _params) do
        users = Repo.all(Usermanage)
                |> Enum.map(fn struct -> struct_to_map(struct)  end)
        json conn, users
    end
    @psw_secret "sfowieru091203921idsadfijljxzvcz00zaalkNDSADLKS09800DZMXCMkmsfasdfas123131dffd332d+_="
    def create(conn, %{"account" => account,"password" => password}) do 
        if Usermanage.check_account(account) do
            conn |> send_resp(406, "Duplicate account")
        else 
            hashing_password = :crypto.hash(:sha256, password<>@psw_secret) |> Base.url_encode64()
            Usermanage.insert_user(account,hashing_password)
            conn |> send_resp(201,"Signup successfully")
        end
    end

    def get_user(conn, _params) do
        token = get_token(conn)
        case verify_token(token) do
            {:ok, token_sub_id} ->
                user = Usermanage.get_user_by_id(token_sub_id)
                json conn, %{account: user.account, money: user.money}
            _ ->  send_resp(conn, 404, "Not found")
        end
    end

    def deposit(conn, %{"deposit"=> deposit}) do
        token = get_token(conn)
        #id = Integer.to_string(id)
        case verify_token(token) do
        {:ok, token_sub_id} ->
            if (Usermanage.get_user_by_id(token_sub_id) != nil) do
                money = Usermanage.show_money(token_sub_id)
                money = money + elem(Integer.parse(deposit),0)
                Usermanage.update_money(token_sub_id,money)
                json conn, %{money: money}
            else
                conn |> send_resp(401,"Unauthorized")
            end
        {:error, reason} -> 
            conn |> send_resp(401, reason)
        end
    end

    def withdraw(conn, %{"withdraw"=> withdraw}) do
        token = get_token(conn)
        case verify_token(token) do
            {:ok, token_sub_id} ->
                if (Usermanage.get_user_by_id(token_sub_id) != nil) do
                    money = Usermanage.show_money(token_sub_id)
                    money = money - elem(Integer.parse(withdraw),0)
                    Usermanage.update_money(token_sub_id,money)
                    json conn, %{money: money}
                else
                    conn |> send_resp(401,"Unauthorized")
                end
            {:error, reason} -> 
                conn |> send_resp(401, reason)
        end
        # -------------------------------------------        
    end

    def transfer(conn,%{"receiverid"=>receiverid,"receivername"=>receivername,"money"=>money}) do
        token = get_token(conn)
        case verify_token(token) do
            {:ok, token_sub_id} ->
                if (Usermanage.get_user_by_id(token_sub_id) != nil) do
                    money = elem(Integer.parse(money),0)
                    if elem(Integer.parse(receiverid),0) == Usermanage.show_id(receivername) && token_sub_id !== receiverid do
                        target_money = Usermanage.show_money(receiverid)
                        source_money = Usermanage.show_money(token_sub_id)
                        target_money = target_money + money
                        source_money = source_money - money
                        Usermanage.update_money(receiverid, target_money)
                        Usermanage.update_money(token_sub_id,source_money)
                        json conn, %{money: source_money}                  
                    else 
                        conn |> send_resp(406,"")
                    end            
                else
                conn |> send_resp(403,"")
                end
            {:error, reason} -> 
                conn |> send_resp(401, reason)
        end
        # ----------------------------------        
    end

    # SIGNIN
    def signin(conn,%{"account"=>account,"password"=>password})  do
        password = :crypto.hash(:sha256, password<>@psw_secret) |> Base.url_encode64()
        case token_sign_in(account,password) do
                #{:ok, token, claims} -> json conn, %{accesstoken: token}
                    #{:ok, token, user_info}  ->  json conn, %{accesstoken: token, account: user_info.account, id: user_info.id, money: user_info.money}
                    {:ok, token}  ->  json conn, %{accesstoken: token}
                                _ ->  send_resp(conn, 404, "Not found")
            end
    end

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

    def token_sign_in(account,password) do
        case verify_account_password(account,password) do
            # {:ok, id} -> Guardian.encode_and_sign(Usermanage.get_user(id),%{}, ttl: {1, :minute})
            {:ok, id} ->    #user_info = Usermanage.get_user(id) |> struct_to_map() |> Map.drop([:password]) 
                            {:ok, jwt_encode(Usermanage.get_user(id))}
                    _ ->  {:error, :unauthorized}
        end
    end

    def verify_token(token) do
        # case Guardian.decode_and_verify(token) do
        case jwt_decode(token) do
        {:ok,claim} -> {:ok, claim["sub"]}
                    _ -> {:error, "Unauthorized"}
        end
    end

    #jwt
    @secret_key "UTELcvSwFT9t7u51SxExjsnUXjXTLFCHnUKx5trjsKjQLllCr9PwARorGZRILp56"
    @life_time  60   # minute
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
        # --------------- signature -----------------
        signature = jwt_header<>"."<>jwt_claim
        jwt_signature = :crypto.hmac(:sha256, @secret_key, signature) |> Base.url_encode64()
        token = jwt_header<>"."<>jwt_claim<>"."<>jwt_signature
        token
    end

    def jwt_decode(token) do
        [jwt_header,jwt_claim,jwt_signature]=String.split(token,".", parts: 3) 
        plain_text = jwt_header<>"."<>jwt_claim
        {:ok, claim}       = decode_baseurl64_json(jwt_claim)
        signature_secret = :crypto.hmac(:sha256, @secret_key, plain_text) |> Base.url_encode64()
        if compare_time(signature_secret, jwt_signature,claim) do
            {:ok, claim}
        else
            {:error}
        end
    end

    defp compare_time(signature_secret, jwt_signature,claim) do
        time_now = DateTime.utc_now() |> DateTime.to_unix()
        %{
            "aud" => aud,
            "exp" => exp,
            "iat" => iat,
            "iss" => iss,
            "nbf" => nbf,
            "sub" => sub
          } = claim
        if (exp > time_now) && (signature_secret == jwt_signature) do
            true
        else
            false
        end
    end

    def inspect_token(conn,_params) do
        accesstoken = get_token(conn)
        case jwt_decode(accesstoken) do
        {:ok,claim} ->  user = claim["sub"] |> Usermanage.get_user() |> struct_to_map() |> Map.drop([:password]) 
                        json conn, user 
                        
                _   -> conn |> send_resp(404, "Time out")
        end
    end

    defp get_token(conn) do
        bearer_token = hd(get_req_header(conn,"authorization"))
        ["Bearer", accesstoken] = String.split(bearer_token," ",parts: 2)
        accesstoken
    end
    defp decode_baseurl64_json(baseurl64) do
        {:ok, json}  = baseurl64 |> Base.url_decode64() 
        {:ok, map}       = json |> JSON.decode()
    end


    
    #Oauth
    @app_id "197695828014122"
    @app_secret "dd085e5054471410b9fc55fb1fd4de8e"
    @redirect_url "http://localhost:4000/api/bank/FacebookHandler"
    @facebook_api "https://graph.facebook.com"

    def facebook_login(conn,_params) do
        redirect(conn, external: "https://www.facebook.com/v6.0/dialog/oauth?client_id=#{@app_id}&redirect_uri=#{"http://localhost:4000/api"}&state=#{"{st=state123abc,ds=123456789}"}&response_type=token")
    end
    #exchange code for access token
    def facebook_login_handler(conn, %{"accesstoken"=> access_token}) do

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

 
