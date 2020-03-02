
signinHandler = () => {
  account = document.getElementById("signin_account").value;
  password = document.getElementById("signin_password").value;
  axios({
    method: "post",
    url: "http://localhost:4000/api/bank/Signin",
    data: {
      account: account,
      password: password
    }
  })
    .then(resp => {
      if (resp.data.status === "ok" ){                
        localStorage.setItem("userInfo", JSON.stringify(resp.data.data));
        homeHandler();
      } else {
        alert = document.getElementById("signinAlert")
        alert.className = "alert alert-danger"
        alert.innerHTML = resp.data.message
      }
    })
    .catch(error => console.log(error));
};

signupHandler = () => {
  if ( accountValidate() && passwordValidate() ){
    account = document.getElementById("signup_account").value;
    password = document.getElementById("signup_password").value;
    axios({
      method: "post",
      url: "http://localhost:4000/api/bank/Signup",
      data: {
        account: account,
        password: password
      }
    })
      .then(result => {
        if(result.data.status === "ok"){
          renderSigninHTML()
        } else {
          alert = document.getElementById("accountAlert")
          alert.className = "alert alert-danger"
          alert.innerHTML = result.data.message          
        }
      }
        )
      .catch(error => {
        alert = document.getElementById("accountAlert")
        alert.className = "alert alert-danger"
        alert.innerHTML = error.response.data;
      });
  }
};

depositHandler = () => {
  user = JSON.parse(localStorage.getItem("userInfo"));
  money = document.getElementById("deposit_money").value;
  if( depositValidate() ){
    axios({
      method: "post",
      url: "http://localhost:4000/api/bank/Deposit",
      data: {
        id: user.id,
        deposit: money
      },
      headers: {
        Authorization: `Bearer ${user.accesstoken}`
      }
    })
      .then(resp => {
        if (resp.data.status === "ok"){
          renderHTML(resp.data.data.money);
        } else {
          alert(resp.data.message)
        }
      })
      .catch(error => console.log(error));
  } 
  
};

withdrawHandler = () => {
  user = JSON.parse(localStorage.getItem("userInfo"));
  money = document.getElementById("withdraw_money").value;
  if(withdrawValidate() ){
    axios({
      method: "post",
      url: "http://localhost:4000/api/bank/Withdraw",
      data: {
        id: user.id,
        withdraw: money
      },
      headers: {
        authorization: `Bearer ${user.accesstoken}`
      }
    })
      .then(resp => {
        if (resp.data.status === "ok"){
          renderHTML(resp.data.data.money);
        } else {
          alert(resp.data.message)
        }
      }) 
      .catch(error => console.log(error));
  }
  
};

transferHandler = () => {
  user = JSON.parse(localStorage.getItem("userInfo"));
  money = document.getElementById("transfer_money").value;
  receiverName = document.getElementById("receiver_name").value;
  receiverId = document.getElementById("receiver_id").value;
  axios({
    method: "post",
    url: "http://localhost:4000/api/bank/Transfer",
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
      if(resp.data.status === "ok"){
        renderHTML(resp.data.data.money);
      } else {
        alert(resp.data.message)
      }
    })
    .catch(error => console.log(error));
};

logoutHandler = () => {
  localStorage.removeItem("userInfo");
  renderIndexHTML();
};

loginWithFacebookHandler = () => {
  location.href =
    "https://www.facebook.com/v6.0/dialog/oauth?client_id=197695828014122&redirect_uri=http://localhost:5501/index.html&state=st=state123abc,ds=123456789&response_type=token";
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

renderHTML = (money) => {
    userInfo = JSON.parse(localStorage.getItem("userInfo"))
    
    document.getElementById("main").innerHTML = `
        <div class="container">
        <h2>User: ${userInfo.account} </h2>
        <p style="font-size:50px"> Money in account : ${money} </p>
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
                      <label>Receiver's id</label>
                      <input class="form-control" id="receiver_id" />
                      <label>Reveiver's name</label>
                      <input class="form-control" id="receiver_name" >
                      <label for="money">Money</label>
                      <input class="form-control"  id="transfer_money"></input>        
                </div>
                <div class="modal-footer">
                  <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                  <button class="btn btn-primary"  onclick="transferHandler()" data-dismiss="modal">Transfer</button>
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
        <div class="form-group">
          <div  role="alert" id="accountAlert"></div>
          <label for="account">Account</label>
          <input
            class="form-control"
            type="text"
            name="account"
            id="signup_account"
            onblur ="accountValidate()"            
          />
        </div>
        <div class="form-group">
          <div  role="alert" id="passwordAlert"></div>
          <label for="password">Password</label>
          <input
            class="form-control"
            type="password"
            name="password"
            id="signup_password" 
            onblur = "passwordValidate()"                       
          />
        </div>
        <div class="text-center">
          <button class="btn btn-success" onclick="signupHandler()" >
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
          <input
            type="text"
            class="form-control"
            name="account"
            id="signin_account"
          />
        </div>
        <div class="form-group">
          <label>Password</label>
          <input
            type="password"
            class="form-control"
            name="password"
            id="signin_password"
          />
        </div>
        <div class="text-center">
          <button class="btn btn-success" onclick="signinHandler()">
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
      method: "post",
      url: "http://localhost:4000/api/bank/GetUserInfo",
      data: {
        id: user.id
      },
      headers: {
        authorization: `Bearer ${user.accesstoken}`
      }
    }).then(result => { 
        userInfo = result.data.data      
        renderHTML(userInfo.money);
      }).catch(error => console.log(error));
  } else {
    renderIndexHTML();
  }
};
accountValidate = () => {
  account = document.getElementById("signup_account").value
  alert = document.getElementById("accountAlert")
  if ( account === ""){
    alert.className = "alert alert-danger"
    alert.innerHTML = "Required"
    return false
  } else if ( !account.match("^[a-zA-Z0-9_]*$") ){ //just have character and number
    alert.className = "alert alert-danger"
    alert.innerHTML = "Account should has alphabet and number character"
    return false
  } else {
    alert.className = "alert alert-success"
    alert.innerHTML = "Checked"
    return true
  }
};
passwordValidate = () => {
  password = document.getElementById("signup_password").value
  alert = document.getElementById("passwordAlert")
  if (password === ""){
    alert.className = "alert alert-danger"
    alert.innerHTML = "Required"
    return false
  } else if(password.length <=6 ){
    alert.className = "alert alert-danger"
    alert.innerHTML = "Password must longer than 6 characters"
  }else if( !password.match("^(?=.*[0-9]+.*)(?=.*[a-zA-Z]+.*)[0-9a-zA-Z]{6,}$")){ // Don't allow sepcial character
    alert.className = "alert alert-danger"
    alert.innerHTML = "Password must contain at least one letter, at least one number"
    return false
  } else {
    alert.className = "alert alert-success"
    alert.innerHTML = "Checked"
    return true
  }
};
depositValidate = () =>{
  money = document.getElementById("deposit_money").value
  alert = document.getElementById("depositAlert")
  button = document.getElementById("depositSubmit")
  if ( money.match("^\s*$") ){
      alert.className = "alert alert-danger"
      alert.innerHTML = "Money can't be blank"
      return false
  } else if( !money.match("^[0-9]*$")) {
    alert.className = "alert alert-danger"
    alert.innerHTML = "Money must be positive number"
      return false
  } else{
    alert.className = ""
    alert.innerHTML = ""
    button.disabled = false
      return true
  }
}
withdrawValidate = () => {
  money = document.getElementById("withdraw_money").value
  alert = document.getElementById("withdrawAlert")
  button = document.getElementById("withdrawSubmit")
  if ( money.match("^\s*$") ){
      alert.className = "alert alert-danger"
      alert.innerHTML = "Money can't be blank"
      return false
  } else if( !money.match("^[0-9]*$")) {
    alert.className = "alert alert-danger"
    alert.innerHTML = "Money must be positive number"
      return false
  } else{
    alert.className = ""
    alert.innerHTML = ""
    button.disabled = false
      return true
  }
}

window.onload = () =>{
        if(location.hash) {
        hash = location.hash.substr(1)
        list = hash.split("&")
        token = list[0].split("=")[1]
        axios({
          method:'post',
          url:'http://localhost:4000/api/bank/FacebookHandler',
          data:{
            "accesstoken": token
          }
        }).then(resp=>{
          resp.data.data.account = xoa_dau(resp.data.data.account)
          localStorage.setItem("userInfo",JSON.stringify(resp.data.data))          
        }).catch(error => console.log(error.response))
        }
        homeHandler();
}
        
    








//   window.onload = init()
//   function init(){
//     user =  JSON.parse(localStorage.getItem("userInfo"))
//     href_home   = 'http://localhost:4000/bank'
//     href_signin = 'http://localhost:4000/bank/signin'
//     href_signup = 'http://localhost:4000/bank/singup'
//    if (user != null ) {
//      href = `http://localhost:4000/bank/account/${user.id}/${user.account}`
//      if (location.href != href ){
//       location.replace(`http://localhost:4000/bank/account/${user.id}/${user.account}`)
//      }else {
//       user = JSON.parse(localStorage.getItem("userInfo"))
//       document.getElementById("user_name").innerHTML  = user.account
//       document.getElementById("user_money").innerHTML = user.money
//      }
//     }
//     else{
//       if(location.hash) {
//         hash = location.hash.substr(1)
//         list = hash.split("&")
//         token = list[0].split("=")[1]
//         axios({
//           method:'post',
//           url:'http://localhost:4000/api/bank/FacebookHandler',
//           data:{
//             "accesstoken": token
//           }
//         }).then(result=>{
//           result.data.account = xoa_dau(result.data.account)
//           localStorage.setItem("userInfo",JSON.stringify(result.data))
//           location.reload()
//         }).catch(error => console.log(error.response))
//       }
//         else if (location.href !=  href_home && location.href !=  href_signin && location.href !=  href_signup){
//         location.replace(href_home)
//       }
//     }
//   }