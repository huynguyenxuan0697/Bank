defmodule HelloWeb.DefaultController do
    use HelloWeb, :controller
    alias HelloWeb.Response
        
    def default(conn, _params)do
        Response.error(conn, Response.add_message([],"URL/method not true",404))
    end
    
end