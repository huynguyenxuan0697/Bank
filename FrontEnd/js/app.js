function checkPassword(str)
{
    // at least one number, one lowercase and one uppercase letter
    // at least six characters
    var re = /(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).{8,}/;
    return re.test(str);
}

function checkAccount(str)
{
    //at least one character
    var re = /(?=.*\d).{1,}/;
    return re.test(str);
}

function signinHandler() {
    account = document.getElementById("signin_account").value
    password = document.getElementById("signin_password").value
    axios({
        method: 'post',
        url: 'http://localhost:4000/api/bank/Signin',
        data:{
            "account":account,
            "password":password
        }
    }).then(result =>{
        localStorage.setItem("userInfo",JSON.stringify(result.data))
        location.replace(`http://localhost:8080/account`)
    }).catch(error => {
        alert('Accout or Password is not valid!')
    })
}

function signupHandler(){
    account = document.getElementById("signup_account").value
    password = document.getElementById("signup_password").value
    confirmpassword = document.getElementById("signup_confirm_password").value
    valid = document.getElementById("valid");
    if (password != confirmpassword){
        alert('Confirm password is not correct')
    }
    else{
        if (checkPassword(password) == true && checkAccount(account) == true){
            axios({
                method: 'post',
                url: 'http://localhost:4000/api/bank/Signup',
                data:{
                    "account" :account,
                    "password":password
                }
            }).then(result =>{
                alert('Your account has been created!')
                document.getElementById('signup-close').click();
            }).catch(error => {      
                console.log(error)
            })
        }
        else{
            alert('Account or Password is not valid!')
            valid.style.display = "block"
        }
    }
}

window.onload = function () {
    user = JSON.parse(localStorage.getItem("userInfo"))
    if (user != null){
        axios({
            method: 'get',
            url: 'http://localhost:4000/api/bank/GetUser',
            headers:{
                "Authorization": `Bearer ${user.accesstoken}`
            }
        }).then(result=>{
            document.getElementById("user_name").innerHTML = result.data.account
            document.getElementById("user_money").innerHTML = result.data.money
            //location.href =`http://localhost:4000/bank/account/${user.id}/${user.account}`
        }).catch(error => console.log(error))
    }
}

function depositHandler(){
    user = JSON.parse(localStorage.getItem("userInfo"))
    money = document.getElementById("deposit_money").value
    axios({
        method: 'post',
        url: 'http://localhost:4000/api/bank/Deposit',
        data:{
            "deposit": money
        },
        headers:{
            "Authorization": `Bearer ${user.accesstoken}`
        }
    }).then(result=>{
        document.getElementById("user_money").innerHTML = result.data.money
        document.getElementById('deposit-close').click(); 
    }).catch(error => console.log(error))
}

function withdrawHandler(){
    user = JSON.parse(localStorage.getItem("userInfo")) 
    money = document.getElementById("withdraw_money").value
    axios({
        method: 'post',
        url: 'http://localhost:4000/api/bank/Withdraw',
        data:{
            "withdraw": money
        },
        headers:{
            "authorization": `Bearer ${user.accesstoken}`
        }
    }).then(result=>{
        user.money = result.data.money
        document.getElementById("user_money").innerHTML = result.data.money
        document.getElementById('withdrawal-close').click();
    }).catch(error => console.log(error))
}

function transferHandler(){
    user         = JSON.parse(localStorage.getItem("userInfo"))
    money        = document.getElementById("transfer_money").value
    receiverName = document.getElementById("receiver_name").value
    receiverId   = document.getElementById("receiver_id").value
    axios({
        method: 'post',
        url: 'http://localhost:4000/api/bank/Transfer',
        data:{
            "receiverid": receiverId,
            "receivername": receiverName,
            "money": money,
        },
        headers:{
            "authorization": `Bearer ${user.accesstoken}`
        }
    }).then(result=>{
        user.money = result.data.money
        document.getElementById("user_money").innerHTML = result.data.money
        document.getElementById('transfer-close').click();
    }).catch(error => console.log(error))
}

function logoutHandler(){
    localStorage.removeItem("userInfo")
    location.replace("http://localhost:8080")
}