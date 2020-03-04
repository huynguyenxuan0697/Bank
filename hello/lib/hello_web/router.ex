defmodule HelloWeb.Router do
  use HelloWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    # fetch session store, also fetch cookies
    plug :fetch_session
    # fetch flash storage
    plug :fetch_flash
    # enable CSRF protection
    plug :protect_from_forgery
    # put headers that improve browser security
    plug :put_secure_browser_headers
    # plug :"Controller.test"
    # plug LearningPlug2, %{}
    # plug :test_assign
    # plug HelloWeb.Plugs.SetCurrentUser
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug HelloWeb.Plugs.Auth
  end

  # Other scopes may use custom stacks.
  scope "/api/bank", HelloWeb do
    pipe_through :api
    get "/getallusers", ApiBankController, :show_all
    post "/signup", ApiBankController, :create
    post "/signin", ApiBankController, :signin
    # ------- Facebook oauth ----------------------------------- 
    get  "/loginWithFacebook", ApiBankController, :facebook_login
    post "/facebookHandler", ApiBankController, :facebook_login_handler
    # ------- Auth ---------------------------------------------
    pipe_through :auth
    post "/deposit", ApiBankController, :deposit
    post "/withdraw", ApiBankController, :withdraw
    post "/transfer", ApiBankController, :transfer    
    get  "/getuserinfo", ApiBankController, :get_user_info
    get  "/logout", ApiBankController, :logout
  end
end
