signinHandler = () => {
  if (signinAccountValidate() && signinPasswordValidate()){
    account = document.getElementById("signin_account").value;
    password = document.getElementById("signin_password").value;
    axios({
      method: "post",
      url: "http://localhost:4000/api/bank/signin",
      data: {
        account: account,
        password: password
      }
    })
      .then(resp => {
        if (resp.data.status === "ok") {
          localStorage.setItem("userInfo", JSON.stringify(resp.data.data));
          homeHandler();
        } else {
          signinAlert = document.getElementById("signinAlert");
          signinAlert.className = "alert alert-danger";
          signinAlert.innerHTML = resp.data.message;
        }
      })
      .catch(error => console.log(error));
  }
};

signupHandler = () => {
  if (signupAccountValidate() && signupPasswordValidate()) {
    account = document.getElementById("signup_account").value;
    password = document.getElementById("signup_password").value;
    axios({
      method: "post",
      url: "http://localhost:4000/api/bank/signup",
      data: {
        account: account,
        password: password
      }
    })
      .then(result => {
        if (result.data.status === "ok") {
          alert('Sign up successfully')
          renderSigninHTML();
        } else {
          AccountAlert = document.getElementById("AccountAlert");
          AccountAlert.className = "alert alert-danger";
          AccountAlert.innerHTML = result.data.message;
        }
      })
      .catch(error => {
        AccountAlert = document.getElementById("AccountAlert");
        AccountAlert.className = "alert alert-danger";
        AccountAlert.innerHTML = error.response.data;
      });
  }
};

depositHandler = () => {
  user = JSON.parse(localStorage.getItem("userInfo"));
  money = document.getElementById("deposit_money").value;
  if (depositValidate()) {
    axios({
      method: "post",
      url: "http://localhost:4000/api/bank/deposit",
      data: {
        id: user.id,
        deposit: money
      },
      headers: {
        Authorization: `Bearer ${user.accesstoken}`
      }
    })
      .then(resp => {
        if (resp.data.status === "ok") {
          document.getElementById("user-money").innerHTML = 'Money in account: ' + resp.data.data.money;
        } else {
          alert(resp.data.message);
          if (resp.data.message === 'Unauthorized'){
            localStorage.removeItem("userInfo");
            renderIndexHTML();
          }
        }
      })
      .catch(error => {
        console.log(error);
      });
  }
  else{
    alert('Money must be a positive number!');
  }
};

withdrawHandler = () => {
  user = JSON.parse(localStorage.getItem("userInfo"));
  money = document.getElementById("withdraw_money").value;
  if (withdrawValidate()) {
    axios({
      method: "post",
      url: "http://localhost:4000/api/bank/withdraw",
      data: {
        id: user.id,
        withdraw: money
      },
      headers: {
        authorization: `Bearer ${user.accesstoken}`
      }
    })
      .then(resp => {
        if (resp.data.status === "ok") {
          document.getElementById("user-money").innerHTML = 'Money in account: ' + resp.data.data.money;
        } else {
          alert(resp.data.message);
          if (resp.data.message === 'Unauthorized'){
            localStorage.removeItem("userInfo");
            renderIndexHTML();
          }
        }
      })
      .catch(error => {
        console.log(error);
      });
  }
};

transferHandler = () => {
  user = JSON.parse(localStorage.getItem("userInfo"));
  money = document.getElementById("transfer_money").value;
  receiverName = document.getElementById("receiver_name").value;
  receiverId = document.getElementById("receiver_id").value;
  if (transferIdValidate() && transferNameValidate() && transferMoneyValidate())
  {
    axios({
      method: "post",
      url: "http://localhost:4000/api/bank/transfer",
      data: {
        receiverid: receiverId,
        receivername: receiverName,
        money: money,
        id: user.id
      },
      headers: {
        authorization: `Bearer ${user.accesstoken}`
      }
    })
      .then(resp => {
        if (resp.data.status === "ok") {
          document.getElementById("user-money").innerHTML = 'Money in account: ' + resp.data.data.money;
          document.getElementById("transferClose").click();
        } else {
          alert(resp.data.message);
          if (resp.data.message === 'Unauthorized'){
            localStorage.removeItem("userInfo");
            renderIndexHTML();
          }
        }
      })
      .catch(error => {
        console.log(error);
      });
  }
  else{
    alert('Info is not valid');
  }
};

logoutHandler = () => {
  axios({
    method: "get",
    url: "http://localhost:4000/api/bank/logout",
    headers: {
      authorization: `Bearer ${user.accesstoken}`
    }
  })
    .then(result => {
      if (result.data.status === 'ok'){
        console.log(result.data.message);
        localStorage.removeItem("userInfo");
        renderIndexHTML();
      }
    })
    .catch(error => {
      console.log(error);
    });
  
};

loginWithFacebookHandler = () => {
  location.href =
    "https://www.facebook.com/v6.0/dialog/oauth?client_id=197695828014122&redirect_uri=http://localhost:8080&state=st=state123abc,ds=123456789&response_type=token&auth_type=rerequest&scope=email";
};

xoa_dau = str => {
  str = str.replace(/à|á|ạ|ả|ã|â|ầ|ấ|ậ|ẩ|ẫ|ă|ằ|ắ|ặ|ẳ|ẵ/g, "a");
  str = str.replace(/è|é|ẹ|ẻ|ẽ|ê|ề|ế|ệ|ể|ễ/g, "e");
  str = str.replace(/ì|í|ị|ỉ|ĩ/g, "i");
  str = str.replace(/ò|ó|ọ|ỏ|õ|ô|ồ|ố|ộ|ổ|ỗ|ơ|ờ|ớ|ợ|ở|ỡ/g, "o");
  str = str.replace(/ù|ú|ụ|ủ|ũ|ư|ừ|ứ|ự|ử|ữ/g, "u");
  str = str.replace(/ỳ|ý|ỵ|ỷ|ỹ/g, "y");
  str = str.replace(/đ/g, "d");
  str = str.replace(/À|Á|Ạ|Ả|Ã|Â|Ầ|Ấ|Ậ|Ẩ|Ẫ|Ă|Ằ|Ắ|Ặ|Ẳ|Ẵ/g, "A");
  str = str.replace(/È|É|Ẹ|Ẻ|Ẽ|Ê|Ề|Ế|Ệ|Ể|Ễ/g, "E");
  str = str.replace(/Ì|Í|Ị|Ỉ|Ĩ/g, "I");
  str = str.replace(/Ò|Ó|Ọ|Ỏ|Õ|Ô|Ồ|Ố|Ộ|Ổ|Ỗ|Ơ|Ờ|Ớ|Ợ|Ở|Ỡ/g, "O");
  str = str.replace(/Ù|Ú|Ụ|Ủ|Ũ|Ư|Ừ|Ứ|Ự|Ử|Ữ/g, "U");
  str = str.replace(/Ỳ|Ý|Ỵ|Ỷ|Ỹ/g, "Y");
  str = str.replace(/Đ/g, "D");
  str = str.split(" ").join("");
  return str;
};

renderUserNameHTML = (account) => {
  document.getElementById("user-name").innerHTML = `<h2>User: ${account} </h2>`;
};

renderMainHTML = (money) => {
  userInfo = JSON.parse(localStorage.getItem("userInfo"));

  document.getElementById("main").innerHTML = `
        <div id = "user-name"></div>
        <div class="container">
        <p style="font-size:50px" id="user-money"> Money in account: ${money} </p>
        <a><button  class="btn btn-success" data-toggle="modal" data-target="#deposit">Deposit money</button></a>
        <a><button  class="btn btn-primary" data-toggle="modal" data-target="#withdraw">Withdrawals</button></a>
        <a><button  class="btn btn-primary" data-toggle="modal" data-target="#transfer">Transfer</button></a>
        <a><button  class="btn btn-danger"  onclick="logoutHandler()">Logout</button></a>        
        </div>
        <!-- Deposit Modal -->
        <div class="modal fade" id="deposit" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog" role="document">
              <div class="modal-content">
                <div class="modal-header">
                  <h5 class="modal-title" >Deposit money</h5>
                  <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                  </button>
                </div>
                <div class="modal-body">  
                      <div id ="depositAlert"></div>      
                      <label for="money">Money</label>
                      <input class="form-control" name="deposit" id="deposit_money" onblur="depositValidate()" ></input>    
                </div>
                <div class="modal-footer">
                  <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                  <button  class="btn btn-primary" onclick = "depositHandler()"  id="depositSubmit" data-dismiss="modal" disabled>Deposit</button>
                </div>   
              </div>
            </div>
          </div>
          
          <!-- Withdrawal Modal -->
          <div class="modal fade" id="withdraw" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog" role="document">
              <div class="modal-content">
                <div class="modal-header">
                  <h5 class="modal-title" >Withdraw money</h5>
                  <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                  </button>
                </div>
                <div class="modal-body">
                      <div id= "withdrawAlert"></div>
                      <label>Money</label>
                      <input class="form-control" name="withdraw" id="withdraw_money" onblur="withdrawValidate()"></input>        
                </div>
                <div class="modal-footer">
                  <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                  <button  class="btn btn-primary" onclick="withdrawHandler()" data-dismiss="modal" id="withdrawSubmit" disabled>Withdraw</button>
                </div>  
              </div>
            </div>
          </div>
          
          <!-- Transfer Modal -->
          <div class="modal fade" id="transfer" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog" role="document">
              <div class="modal-content">
                <div class="modal-header">
                  <h5 class="modal-title" >Transfer money</h5>
                  <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                  </button>
                </div>
                <div class="modal-body">
                      <div id= "transferIdAlert"></div>
                      <label>Receiver's id</label>
                      <input class="form-control" id="receiver_id" onblur="transferIdValidate()"></input>
                      </br>
                      <div id= "transferNameAlert"></div>
                      <label>Reveiver's name</label>
                      <input class="form-control" id="receiver_name" onblur="transferNameValidate()"></input>
                      </br>
                      <div id= "transferMoneyAlert"></div>
                      <label for="money">Money</label>
                      <input class="form-control"  id="transfer_money" onblur="transferMoneyValidate()"></input>        
                </div>
                <div class="modal-footer">
                  <button id="transferClose" type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                  <button id="transferSubmit" class="btn btn-primary"  onclick="transferHandler()">Transfer</button>
                </div>  
              </div>
            </div>
          </div>          
        `;
};
renderIndexHTML = () => {
  document.getElementById("main").innerHTML = `
    <div class="container">
          <button class="btn btn-primary" onclick="renderSigninHTML()">Sign in</button>            
          <button class="btn btn-primary" onclick="loginWithFacebookHandler()" >Sign in with Facebook</button>            
          <button class="btn btn-primary" onclick="renderSignupHTML()">Sign up</button>      
      </div>`;
};
renderSignupHTML = () => {
  document.getElementById("main").innerHTML = `
    <div class="container">
        <h1 class="text-center">Sign up</h1>
        <div  role="alert" id="AccountAlert"></div>
        <div class="form-group">
          <label for="account">Account</label>
          <input
            class="form-control"
            type="text"
            name="account"
            id="signup_account"
            onblur ="signupAccountValidate()"            
          />
          </br>
          <div  role="alert" id="signupAccountAlert"></div>
        </div>
        <div class="form-group">
          <label for="password">Password</label>
          <input
            class="form-control"
            type="password"
            name="password"
            id="signup_password" 
            onblur = "signupPasswordValidate()"                       
          />
          </br>
          <div  role="alert" id="signupPasswordAlert"></div>
        </div>
        <div class="text-center">
          <button id="btn-signup" class="btn btn-info" onclick="signupHandler()">
            Sign up
          </button>
        </div>
      </div>
`;
};
renderSigninHTML = () => {
  document.getElementById("main").innerHTML = `
    <div class="container signin">
        <h1 class="text-center">Sign in</h1>
        <div id="signinAlert"></div>
        <div class="form-group">
          <label>Account</label>
          <input type="text" class="form-control" name="account"
          id="signin_account" onblur="signinAccountValidate()"/>
          </br>
          <div  role="alert" id="signinAccountAlert"></div>
        </div>
        <div class="form-group">
          <label>Password</label>
          <input type="password" class="form-control" name="password" 
          id="signin_password" onblur = "signinPasswordValidate()"
          />
          </br>
          <div  role="alert" id="signinPasswordAlert"></div>
        </div>
        <div class="text-center">
          <button class="btn btn-info" onclick="signinHandler()">
            Submit
          </button>
        </div>
      </div>
`;
};
homeHandler = () => {
  user = JSON.parse(localStorage.getItem("userInfo"));
  if (user) {
    axios({
      method: "get",
      url: "http://localhost:4000/api/bank/get-user-info",
      headers: {
        authorization: `Bearer ${user.accesstoken}`
      }
    })
      .then(result => {
        if (result.data.status === 'ok')
        {
          account = result.data.data.account;
          money = result.data.data.money;
          renderMainHTML(money);
          renderUserNameHTML(account);
        }
        else{
          if (result.data.message === 'Unauthorized'){
            localStorage.removeItem("userInfo");
            renderIndexHTML();
          }
        }
      })
      .catch(error => {
        console.log(error);
      });
  } else {
    renderIndexHTML();
  }
};

signupAccountValidate = () => {
  account = document.getElementById("signup_account").value;
  signupAccountAlert = document.getElementById("signupAccountAlert");
  if (account === "") {
    signupAccountAlert.className = "alert alert-danger";
    signupAccountAlert.innerHTML = "Required";
    return false;
  } else if (!account.match("^[a-zA-Z0-9_]*$")) {
    //just have character and number
    signupAccountAlert.className = "alert alert-danger";
    signupAccountAlert.innerHTML = "Account should has alphabet and number character";
    return false;
  } else {
    signupAccountAlert.className = "alert alert-success";
    signupAccountAlert.innerHTML = "Checked";
    return true;
  }
};

signupPasswordValidate = () => {
  password = document.getElementById("signup_password").value;
  signupPasswordAlert = document.getElementById("signupPasswordAlert");
  if (password === "") {
    signupPasswordAlert.className = "alert alert-danger";
    signupPasswordAlert.innerHTML = "Required";
    return false;
  } else if (password.length <= 6) {
    signupPasswordAlert.className = "alert alert-danger";
    signupPasswordAlert.innerHTML = "Password must longer than 6 characters";
  } else if (
    !password.match("^(?=.*[0-9]+.*)(?=.*[a-zA-Z]+.*)[0-9a-zA-Z]{6,}$")
  ) {
    // Don't allow sepcial character
    signupPasswordAlert.className = "alert alert-danger";
    signupPasswordAlert.innerHTML =
      "Password must contain at least one letter, at least one number";
    return false;
  } else {
    signupPasswordAlert.className = "alert alert-success";
    signupPasswordAlert.innerHTML = "Checked";
    return true;
  }
};

signinAccountValidate = () => {
  account = document.getElementById("signin_account").value;
  signinAccountAlert = document.getElementById("signinAccountAlert");
  if (account === ""){
    signinAccountAlert.className = "alert alert-danger";
    signinAccountAlert.innerHTML = "Required";
    return false;
  }
  else {
    signinAccountAlert.className = "alert alert-success";
    signinAccountAlert.innerHTML = "Checked";
    return true;
  }
};

signinPasswordValidate = () => {
  password = document.getElementById("signin_password").value;
  signinPasswordAlert = document.getElementById("signinPasswordAlert");
  if (password === ""){
    signinPasswordAlert.className = "alert alert-danger";
    signinPasswordAlert.innerHTML = "Required";
    return false;
  }
  else {
    signinPasswordAlert.className = "alert alert-success";
    signinPasswordAlert.innerHTML = "Checked";
    return true;
  }
};

depositValidate = () => {
  money = document.getElementById("deposit_money").value;
  depositAlert = document.getElementById("depositAlert");
  button = document.getElementById("depositSubmit");
  if (money.match("^s*$")) {
    depositAlert.className = "alert alert-danger";
    depositAlert.innerHTML = "Money can't be blank";
    if (button.disabled == false)
      button.disabled = true;
    return false;
  } else if (!money.match("^[0-9]*$")) {
    depositAlert.className = "alert alert-danger";
    depositAlert.innerHTML = "Money must be positive number";
    if (button.disabled == false)
      button.disabled = true;
    return false;
  } else if (money.length > 10) {
    depositAlert.className = "alert alert-danger";
    depositAlert.innerHTML = "Length of number must be less than 10";
    if (button.disabled == false)
      button.disabled = true;
    return false;
  } else {
    depositAlert.className = "";
    depositAlert.innerHTML = "";
    button.disabled = false;
    return true;
  }
};

withdrawValidate = () => {
  money = document.getElementById("withdraw_money").value;
  withdrawAlert = document.getElementById("withdrawAlert");
  button = document.getElementById("withdrawSubmit");
  if (money.match("^s*$")) {
    withdrawAlert.className = "alert alert-danger";
    withdrawAlert.innerHTML = "Money can't be blank";
    if (button.disabled == false)
      button.disabled = true;
    return false;
  } else if (!money.match("^[0-9]*$")) {
    withdrawAlert.className = "alert alert-danger";
    withdrawAlert.innerHTML = "Money must be positive number";
    if (button.disabled == false)
      button.disabled = true;
    return false;
  } else if (money.length > 10) {
    withdrawAlert.className = "alert alert-danger";
    withdrawAlert.innerHTML = "Length of number must be less than 10";
    if (button.disabled == false)
      button.disabled = true;
    return false;
  } else {
    withdrawAlert.className = "";
    withdrawAlert.innerHTML = "";
    button.disabled = false;
    return true;
  }
};

transferIdValidate = () => {
  receiver_id = document.getElementById("receiver_id").value;
  transferIdAlert = document.getElementById("transferIdAlert");

  if (receiver_id.match("^s*$")) {
    transferIdAlert.className = "alert alert-danger";
    transferIdAlert.innerHTML = "Id can't be blank";
    return false;
  } else if (!receiver_id.match("^[0-9]*$")) {
    transferIdAlert.className = "alert alert-danger";
    transferIdAlert.innerHTML = "Id must be positive number";
    return false;
  } else {
    transferIdAlert.className = "";
    transferIdAlert.innerHTML = "";
    return true;
  }
};

transferNameValidate = () => {
  receiver_name = document.getElementById("receiver_name").value;
  transferNameAlert = document.getElementById("transferNameAlert");
  button = document.getElementById("transferSubmit");
  if (receiver_name.match("^s*$")) {
    transferNameAlert.className = "alert alert-danger";
    transferNameAlert.innerHTML = "Receiver name can't be blank";
    return false;
  } else if (!receiver_name.match("^[a-zA-Z0-9_]*$")) {
    transferNameAlert.className = "alert alert-danger";
    transferNameAlert.innerHTML = "Receiver name should has alphabet and number character";
    return false;
  } else {
    transferNameAlert.className = "";
    transferNameAlert.innerHTML = "";
    return true;
  }
};

transferMoneyValidate = () => {
  money = document.getElementById("transfer_money").value;
  transferMoneyAlert = document.getElementById("transferMoneyAlert");
  button = document.getElementById("transferSubmit");
  if (money.match("^s*$")) {
    transferMoneyAlert.className = "alert alert-danger";
    transferMoneyAlert.innerHTML = "Money can't be blank";
    return false;
  } else if (!money.match("^[0-9]*$")) {
    transferMoneyAlert.className = "alert alert-danger";
    transferMoneyAlert.innerHTML = "Money must be positive number";
    return false;
  } else if (money.length > 10) {
    transferMoneyAlert.className = "alert alert-danger";
    transferMoneyAlert.innerHTML = "Length of number must be less than 10";
    return false;
  } else {
    transferMoneyAlert.className = "";
    transferMoneyAlert.innerHTML = "";
    return true;
  }
};

window.onload = () => {
  if (location.hash) {
    hash = location.hash.substr(1);
    list = hash.split("&");
    token = list[0].split("=")[1];
    axios({
      method: "post",
      url: "http://localhost:4000/api/bank/facebook-handler",
      data: {
        accesstoken: token
      }
    })
      .then(resp => {
        //resp.data.data.account = xoa_dau(resp.data.data.account);
        localStorage.setItem("userInfo", JSON.stringify(resp.data.data));
        location.replace("http://localhost:8080");
        homeHandler();
      })
      .catch(error => console.log(error.response));
  } else {
    homeHandler();
  }
};
