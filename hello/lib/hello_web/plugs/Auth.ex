defmodule HelloWeb.Plugs.Auth do
  import Plug.Conn
  import Phoenix.Controller
  alias HelloWeb.Router.Helpers
  alias HelloWeb.ApiBankController

  def init(_params) do
  end

  def call(conn, _params) do
    bearer_token = hd(get_req_header(conn, "accesstoken"))
    ["Bearer", token] = String.split(bearer_token, " ", parts: 2)

    case ApiBAnkController.jwt_decode(token) do
      {:ok, claim} -> conn
      _ -> conn |> send_resp(404, "Unauthorized")
    end
  end
end
