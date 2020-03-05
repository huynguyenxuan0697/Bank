defmodule HelloWeb.Plugs.CheckMethod do
    import Plug.Conn
    # import Phoenix.Controller
    use Phoenix.Controller
    alias HelloWeb.Response

    def init(_params) do
    end
  
    def call(conn, _params) do
        method = conn.method
        if(
            method !== "GET"  &&
            method !== "POST" &&
            method !== "PUT"  &&
            method !== "DELETE"
        ) do
            Response.error(conn,Response.add_message([],"Method is not supported",404))
        else
            conn
        end
        
    end

end