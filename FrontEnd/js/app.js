accountValidate = () => {
    account = document.getElementById("signup_account").value
    alert = document.getElementById("accountAlert")
    if ( account === ""){
        return false
    } else if ( !account.match("^[a-zA-Z0-9_]*$") ){
        return false
    } else {
    return true
    }
};

passwordValidate = () => {
    password = document.getElementById("signup_password").value
    alert = document.getElementById("passwordAlert")
    if (password === ""){
        return false
    }
    else if( !password.match("^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])\w{8,}$")){
        return false
    } else {
        return true
    }
};

moneyValidate = function(money){
    if ( money.match("^\s*$") ){
        return false
    } else if( !money.match("^[1-9]*$")) {
        return false
    } else{
        return true
    }
}

function signinHandler() {
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
    .then(result => {
        if (result.data.status == "ok") {
            localStorage.setItem("userInfo", JSON.stringify(result.data.data));
            location.replace(`http://localhost:8080/account`);
        } else {
            alert = document.getElementById("signin-alert");
            alert.innerHTML = result.data.message;
            alert.style.display = "block";
        }
    })
    .catch(error => console.log(error));
}

function loginWithFacebookHandler() {
    location.href =
    "https://www.facebook.com/v6.0/dialog/oauth?client_id=197695828014122&redirect_uri=http://localhost:8080&auth_type=rerequest&scope=email&response_type=token";
}

function signupHandler() {
    account = document.getElementById("signup_account").value;
    password = document.getElementById("signup_password").value;
    confirmpassword = document.getElementById("signup_confirm_password").value;
    signUpAlert = document.getElementById("signup-alert");
    if (password !== confirmpassword) {
        signUpAlert.innerHTML = "Confirmpassword not match";
        signUpAlert.style.display = "block";
    } else {
        if (accountValidate() && passwordValidate()) {
            axios({
                method: "post",
                url: "http://localhost:4000/api/bank/Signup",
                data: {
                    account: account,
                    password: password
                }
            })
            .then(result => {
                if (result.data.status == "ok") {
                    alert("Your account has been created!");
                    document.getElementById("signup-close").click();
                } else {
                    signUpAlert.innerHTML = result.data.message;
                    signUpAlert.style.display = "block";
                }
            })
            .catch(error => {
                signUpAlert.innerHTML = error.response.data;
                signUpAlert.style.display = "block";
            });
        } else {
        //alert('Account or Password is not valid');
            signUpAlert.innerHTML = "Account or Password is not valid";
            signUpAlert.style.display = "block";
        }
    }
}

window.onload = function() {
    user = JSON.parse(localStorage.getItem("userInfo"));
    if (user != null) {
        if (location.pathname == "/")
            location.replace("http://localhost:8080/account");
            axios({
            method: "get",
            url: "http://localhost:4000/api/bank/GetUser",
            headers: {
                Authorization: `Bearer ${user.accesstoken}`
            }
        })
        .then(result => {
            document.getElementById("user_name").innerHTML =
            result.data.data.account;
            document.getElementById("user_money").innerHTML =
            result.data.data.money;
            //location.href =`http://localhost:4000/bank/account/${user.id}/${user.account}`
        })
        .catch(error => console.log(error));
    } else {
        if (location.pathname == "/account")
            location.replace("http://localhost:8080");
        if (location.hash) {
        hash = this.location.hash.substr(1);
        list = hash.split("&");
        token = list[0].split("=")[1];
        axios({
            method: "post",
            url: "http://localhost:4000/api/bank/FacebookHandler",
            data: {
            accesstoken: token
            }
        })
            .then(result => {
            localStorage.setItem("userInfo", JSON.stringify(result.data.data));
            location.replace(`http://localhost:8080/account`);
            })
            .catch(error => {
            console.log(error);
            //alert("fb access denied")
            document.getElementById("fb-alert").style.display = "block";
            });
        }
    }
};

function depositHandler() {
    user = JSON.parse(localStorage.getItem("userInfo"));
    money = document.getElementById("deposit_money").value;
    if (moneyValidate(money)){
        axios({
            method: "post",
            url: "http://localhost:4000/api/bank/Deposit",
            data: {
                deposit: money
            },
            headers: {
                Authorization: `Bearer ${user.accesstoken}`
            }
        })
            .then(result => {
                document.getElementById("user_money").innerHTML = result.data.data.money;
                document.getElementById("deposit-close").click();
            })
            .catch(error => console.log(error));
    }
    else{
        alert('Money is not valid');
    }
}

function withdrawHandler() {
    user = JSON.parse(localStorage.getItem("userInfo"));
    money = document.getElementById("withdraw_money").value;
    if (moneyValidate(money)){
        axios({
            method: "post",
            url: "http://localhost:4000/api/bank/Withdraw",
            data: {
                withdraw: money
            },
            headers: {
                authorization: `Bearer ${user.accesstoken}`
            }
        })
            .then(result => {
                if (result.data.status == 'ok'){
                    document.getElementById("user_money").innerHTML = result.data.data.money;
                    document.getElementById("withdrawal-close").click();
                }
                else{
                    alert(result.data.message)
                }
            })
            .catch(error => console.log(error));
    }
    else{
        alert('Money is not valid');
    }
}

function transferHandler() {
    user = JSON.parse(localStorage.getItem("userInfo"));
    money = document.getElementById("transfer_money").value;
    receiverName = document.getElementById("receiver_name").value;
    receiverId = document.getElementById("receiver_id").value;
    if (moneyValidate(money) && receiverId != '' && receiverName != '')
    {
        axios({
            method: "post",
            url: "http://localhost:4000/api/bank/Transfer",
            data: {
            receiverid: receiverId,
            receivername: receiverName,
            money: money
            },
            headers: {
            authorization: `Bearer ${user.accesstoken}`
            }
        })
            .then(result => {
                if (result.data.status == 'ok'){
                    document.getElementById("user_money").innerHTML = result.data.data.money;
                    document.getElementById("transfer-close").click();
                }
                else{
                    alert(result.data.message)
                }
            })
            .catch(error => console.log(error));
    }
    else{
        alert('Invalid input! Please check again');
    }
}

function logoutHandler() {
    localStorage.removeItem("userInfo");
    location.replace("http://localhost:8080");
}
