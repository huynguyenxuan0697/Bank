defmodule HelloWeb.ApiBankController do
    use HelloWeb,:controller
    alias HelloWeb.Router.Helpers
    alias Hello.{Repo,Usermanage,Guardian}
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
    @secret_key "UTELcvSwFT9t7u51SxExjsnUXjXTLFCHnUKx5trjsKjQLllCr9PwARorGZRILp56"
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

    def deposit(conn, %{"id"=> id,"deposit"=> deposit}) do
        token = get_token(conn)
        id = Integer.to_string(id)
        case verify_token(token) do
        {:ok, token_sub_id} ->
            cond do
                (token_sub_id != id )  ->
                    resp_error(conn,"Accesstoken don't come with this id")
                true ->
                    case validate_money(deposit) do
                        {:ok,message}       ->  
                            money = add_money(id,deposit)                            
                            # 
                            case Usermanage.update_money(id,money) do
                                {:ok , struct}      ->  resp_ok(conn, %{money: money})                                                              
                                {:error, changeset} ->  message = money_error_parse(changeset.errors)
                                                        resp_error(conn, message)
                                                _   ->  resp_error(conn,"Unknown")
                            end
                        {:error, message}   ->  resp_error(conn, message)
                            _               ->  resp_error(conn,"Unknown")
                    end                    
            end
        {:error, message} -> 
            resp_error(conn,message)
        _ ->
            resp_error(conn,"Unknown")
        end
    end

    defp add_money(id,deposit) do
        money = Usermanage.show_money(id)
        money = money + elem(Integer.parse(deposit),0)        
    end

    def sub_money(id,withdraw) do
        money    = Usermanage.show_money(id)
        withdraw = elem(Integer.parse(withdraw),0)        
        if (money >= withdraw) do            
            money    = money - withdraw
            {:ok, money}
        else
            {:error, "Money in your account is not enough"}
        end
        
    end

    defp validate_money(money) do
        cond do
        String.match?(money,~r/^\s*$/)      -> {:error, "Money can't be blank"}
        !String.match?(money,~r/^[0-9]*$/ ) -> {:error, "Money must be positive number"}
                                    true    -> {:ok, "Valid money"}
        end
    end

    def withdraw(conn, %{"id"=> id,"withdraw"=> withdraw}) do
        token = get_token(conn)
        id = Integer.to_string(id)
        case verify_token(token) do
            {:ok, token_sub_id} ->
                cond do
                    (token_sub_id != id )  ->
                        resp_error(conn,"Accesstoken don't come with this id")
                    true ->
                        case validate_money(withdraw) do
                            {:ok,message}       ->                                  
                                case sub_money(id,withdraw) do
                                    {:ok, money} ->
                                        case Usermanage.update_money(id,money) do
                                            {:ok , struct}      ->  resp_ok(conn, %{money: money})                                                              
                                            {:error, changeset} ->  message = money_error_parse(changeset.errors)
                                                                    resp_error(conn, message)
                                                            _   ->  resp_error(conn,"Unknown")
                                        end
                                    {:error, message} -> 
                                        resp_error(conn, message)
                                end                                                                                          
                            {:error, message}   ->  resp_error(conn, message)
                                _               ->  resp_error(conn,"Unknown")
                        end                    
                end
           {:error, message} -> 
            resp_error(conn,message)
            _ ->
            resp_error(conn,"Unknown")
            end   
    end

    def transfer(conn,%{"receiverid"=>receiverid,"receivername"=>receivername,"money"=>money,"id"=>id}) do
        id = Integer.to_string(id)
        cond do
            String.match?(receiverid ,~r/^\s*$/) -> 
                resp_error(conn,"Receiver id can't be blank")
            String.match?(receivername ,~r/^\s*$/) -> 
                resp_error(conn,"Receiver name can't be blank")            
            !String.match?(receiverid,~r/^[0-9]*$/ ) -> 
                resp_error(conn,"Receiver's id must be number")
            elem(Integer.parse(receiverid),0) !== Usermanage.show_id(receivername) ->
                resp_error(conn,"Account and id are not matched")
            id === receiverid ->  
                resp_error(conn,"Receiver id is must different than your id")
            true    -> # Processing token and money                    
                    token = get_token(conn)        
                    case verify_token(token) do
                        {:ok, token_sub_id} ->        
                                cond do 
                                    token_sub_id != id    -> 
                                        resp_error(conn,"Accesstoken don't come with this id")
                                    true   -> 
                                        case validate_money(money) do
                                            {:ok,message}       ->  
                                                target_money = add_money(receiverid,money)
                                                case  sub_money(id,money) do
                                                    {:ok, source_money} ->
                                                        case Usermanage.update_money(id, source_money) do
                                                            {:ok , source_struct}      ->  
                                                                case Usermanage.update_money(receiverid,target_money) do
                                                                    {:ok , target_struct}      ->  resp_ok(conn, %{money: source_money})                                                              
                                                                    {:error, changeset} ->  message = money_error_parse(changeset.errors)
                                                                                            resp_error(conn, message)
                                                                                    _   ->  resp_error(conn,"Unknown")
                                                                end
                                                            {:error, changeset} ->  message = money_error_parse(changeset.errors)
                                                                                    resp_error(conn, message)
                                                                            _   ->  resp_error(conn,"Unknown")
                                                        end
                                                    {:error, message} ->
                                                        resp_error(conn, message)
                                                end                                                        
                                                
                                                
                                            {:error, message}   ->  resp_error(conn, message)
                                                _               ->  resp_error(conn,"Unknown")
                                        end              
                                end   
                        {:error, message} -> 
                            resp_error(conn,message)
                        _ ->
                            resp_error(conn,"Unknown")
            end                     
        end            
    end

    def get_user_info(conn,%{"id"=>id}) do
        token = get_token(conn)
        id = Integer.to_string(id)
        case verify_token(token) do
            {:ok, token_sub_id} ->
                if (token_sub_id == id ) do
                    user = Usermanage.get_user(id) |> struct_to_map() |> Map.drop([:password]) 
                    resp_ok(conn,user)
                else
                    resp_error(conn,"Accesstoken doesn;t come with this id")
                end
            {:error, message} -> 
                resp_error(conn,message)
            _ ->
                resp_error(conn,"Unknown")
            end



    end
    
    def signin(conn,%{"account"=>account,"password"=>password})  do
        password = :crypto.hash(:sha256, password<>@psw_secret) |> Base.url_encode64()
        case token_sign_in(account,password) do
            #  {:ok, token, claims} -> json conn, %{accesstoken: token}
                    {:ok, token, user_info}  ->  
                        data = %{accesstoken: token, id: user_info.id, account: user_info.account}
                        resp_ok(conn, data)
                    _ ->  
                        resp_error(conn,"Account or password is not true")
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
            {:ok, id} ->    user_info = Usermanage.get_user(id) |> struct_to_map() |> Map.drop([:password]) 
                            {:ok, jwt_encode(Usermanage.get_user(id)), user_info }
                    _ ->  {:error, :unauthorized}
        end
    end

    def verify_token(token) do
        # case Guardian.decode_and_verify(token) do
        case jwt_decode(token) do
        {:ok, data}       -> {:ok, data}
        {:error, message} -> {:error, message}
                  _       -> {:error, "Unknown"}
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
        # --------------- signature -----------------
        signature = jwt_header<>"."<>jwt_claim
        jwt_signature = :crypto.hmac(:sha256, @secret_key, signature) |> Base.url_encode64()
        token = jwt_header<>"."<>jwt_claim<>"."<>jwt_signature
        token
    end

    def jwt_decode(token) do
        [jwt_header,jwt_claim,jwt_signature]=String.split(token,".", parts: 3) 
        plain_text         = jwt_header<>"."<>jwt_claim
        {:ok, claim}       = decode_baseurl64_json(jwt_claim)
        signature_secret = :crypto.hmac(:sha256, @secret_key, plain_text) |> Base.url_encode64()
        case compare_time(signature_secret, jwt_signature,claim) do
            {:error, message}  ->  {:error, message}
            {:ok, message}     ->  {:ok, claim["sub"] }
                        _      ->  {:error, "Unknown"}
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
          cond do 
            (exp <= time_now)                   -> {:error, "Token is expired"}
            (signature_secret != jwt_signature) -> {:error, "Invalid token"}
                                        true    -> {:ok, "Valid Token"}
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

 
