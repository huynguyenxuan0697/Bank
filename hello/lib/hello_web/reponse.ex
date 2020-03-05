defmodule HelloWeb.Response do
    use HelloWeb, :controller
    def error(conn, error_list) do
        resp = %{
          status: "error",
          error_list: error_list
        }
    
        conn |> json(resp)
    end

      def ok(conn, data) do
        resp = %{
          status: "ok",
          data: data
        }
    
        conn |> json(resp)
      end

      def add_message(error_list, message, error_code) do
        message = %{
          message: message,
          error_code: error_code
        }
    
        [message | error_list]
      end
end
