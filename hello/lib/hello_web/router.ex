defmodule HelloWeb.Router do
  use HelloWeb, :router
  

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session # fetch session store, also fetch cookies
    plug :fetch_flash # fetch flash storage
    plug :protect_from_forgery # enable CSRF protection
    plug :put_secure_browser_headers # put headers that improve browser security
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



  scope "/", HelloWeb do
    pipe_through :browser
    get  "/", PageController, :index
    #get  "/bank",BankController,:index
    #get  "/bank/signup",BankController, :signup
    #get  "/bank/signin",BankController, :signin
    #get  "/bank/account/:id/:account", BankController, :account
  end

  


  # Other scopes may use custom stacks.
  scope "/api/bank", HelloWeb do
    pipe_through :api
    #get  "/get-all-users" ,ApiBankController, :show_all
    post "/signup"      ,ApiBankController, :create
    post "/signin"      ,ApiBankController, :signin
    #------- Facebook oauth ----------------------------------- 
    get "/login-with-facebook",  ApiBankController, :facebook_login
    post "/facebook-handler"  ,  ApiBankController, :facebook_login_handler  
    #------- Auth ---------------------------------------------
    pipe_through :auth
    post "/deposit"     ,ApiBankController, :deposit
    post "/withdraw"    ,ApiBankController, :withdraw
    post "/transfer"    ,ApiBankController, :transfer
    get "/get-user-info", ApiBankController, :get_user_info
    get  "/logout", ApiBankController, :logout
  end
  
end

