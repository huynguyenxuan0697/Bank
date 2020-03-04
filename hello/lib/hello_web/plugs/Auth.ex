defmodule HelloWeb.Plugs.Auth do
    import Plug.Conn
    import Phoenix.Controller
    alias HelloWeb.Router.Helpers
    alias HelloWeb.ApiBankController
    alias Hello.Token

    @secret_key "UTELcvSwFT9t7u51SxExjsnUXjXTLFCHnUKx5trjsKjQLllCr9PwARorGZRILp56"
    def init(_params) do
    end

    def call(conn, _params) do
        author = get_req_header(conn,"authorization")
        cond do
        author === [] ->
            resp_error(conn, "Unauthorized")
        true ->
            bearer_token = hd(author)
            with(["Bearer", accesstoken]<- String.split(bearer_token," ",parts: 2),
                {:ok,id} <- jwt_decode(accesstoken) )        
            do  
                conn = assign(conn, :id, id)                   
            else
            {:error, message} ->
                resp_error(conn,message)
            _ ->
                resp_error(conn,"Invalid token")
            end
        end
    end

    def jwt_decode(token) do
        [jwt_header,jwt_claim,jwt_signature]=String.split(token,".", parts: 3) 
        plain_text         = jwt_header<>"."<>jwt_claim
        {:ok, claim}       = decode_baseurl64_json(jwt_claim)
        # get secret
        secret = Token.get_secret(claim["sub"])
        if secret !== nil do
        signature_secret = :crypto.hmac(:sha256, secret, plain_text) |> Base.url_encode64()
        case compare_time(signature_secret, jwt_signature,claim) do
            {:error, message}  ->  {:error, message}
            {:ok, message}     ->  {:ok, claim["sub"] }
                        _      ->  {:error, "Unknown"}
        end
        else
            {:error, "You have been logged out"}
        end
    end

    defp decode_baseurl64_json(baseurl64) do
        {:ok, json}  = baseurl64 |> Base.url_decode64() 
        {:ok, map}       = json |> JSON.decode()
    end

    defp resp_error(conn,message) do
        resp = %{
            status: "error",
            message: message
        }
        conn |> json resp
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
end