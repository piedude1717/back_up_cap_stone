// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "hardhat/console.sol";

contract tollInfrastructure {
    address private owner;
    infrastructure[] private infStructArray; 
    individualUser[] private userStructArray; 

    string accountWarning = "Please call the create an account function";
    string infNotFoundWarning = "The infrastructure you are looking for was not find, please try again!";

    struct individualUser {
        address payable userWallet; 
        string  userFirstName;
        string  userLastName;
        uint userType; //different users have to pay different amounts
        uint totalInfrastructureUsage; //would need a way of knowing how much they have used the infrastructure
        uint totalPayed; 
        string infName;
    }
    //we could either have 1 SC for all infrastructures or each infrastructure gets its own sc
    struct infrastructure {
        address payable infWallet; 
        string  infName;
        uint member_type1_threshold;
        uint member_type2_threshold; 
        uint member_type3_threshold;
        uint member_type1_cost; 
        uint member_type2_cost;
        uint member_type3_cost; 
        uint totalRevenue;
        uint withdrawableRevenue; 
        uint totalVisits;  
    }

    event CreateAccount(string accountWarning);
    event noInfFound(string infNotFoundWarning);
    event userPaymentSuccess(uint userCost, string firstName, string lastName , string infName);
    event printinfArray(string name, address payable wallet, uint totalRevenue, uint withdrawableRevenue, uint totalVisits);
    event printIndUserArray(string fname, string lname, address payable wallet, uint totalPayed, uint userType);
    event insufficientFunds(uint amountToWithdraw, uint withdrawableRevenue, string infName, address payable infWallet);
    event successfulWithdrawal(string infName, address payable wallet, string successMessage);
    event sendCost(string costString, uint userCost);
    constructor()  {
        owner = msg.sender;
    }


    function deposit(address walletAddress) payable public {}

    function checkInfNameIsNotAlreadyInArray(string memory infName) private returns(bool) {
         for (uint i = 0; i < infStructArray.length; i++) {
            if (keccak256(bytes(infName)) == keccak256(bytes(infStructArray[i].infName))) {
                return true; 
            }
        }
        return false;

    }

    function addInfStructure(address payable infWallet, string memory infName, uint member_type1_cost, uint member_type2_cost, uint member_type3_cost, uint member_type1_threshold, uint member_type2_threshold, uint member_type3_threshold) public {
        require(msg.sender == owner, "You must be the owner of the contract to add a new infrastructure, please contact the owner!");
        require(checkInfNameIsNotAlreadyInArray(infName) == false, "This Name is already in use, please choose another name and try again.");
        infrastructure memory newInf; 
        newInf.infWallet = infWallet; 
        newInf.infName = infName; 
        newInf.member_type1_cost = member_type1_cost;
        newInf.member_type2_cost = member_type2_cost; 
        newInf.member_type3_cost = member_type3_cost; 
        newInf.member_type1_threshold = member_type1_threshold;
        newInf.member_type2_threshold = member_type2_threshold; 
        newInf.member_type3_threshold = member_type3_threshold; 
        infStructArray.push(newInf);
    }

    function addUserToNewInf(individualUser memory currUser, string memory infName) private returns (individualUser memory){
        individualUser memory newUser; 
        newUser.userFirstName = currUser.userFirstName; 
        newUser.userLastName = currUser.userLastName;
        newUser.infName = infName; 
        newUser.userType = 1; 
        newUser.userWallet = currUser.userWallet; 
        userStructArray.push(newUser);
        return newUser;

    } //todo

    //TODO; need to sift through structs to find the infrsatureu and user that are in teh database
    function findUserInDataBase(address payable userAddress, string memory infName) private returns(individualUser memory){
        for (uint i = 0; i < userStructArray.length; i++) {
            if (userAddress == userStructArray[i].userWallet && keccak256(bytes(infName)) == keccak256(bytes(userStructArray[i].infName))){
                return userStructArray[i];
            }
            if (userAddress == userStructArray[i].userWallet && keccak256(bytes(infName)) == keccak256(bytes(userStructArray[i].infName))) {
                return addUserToNewInf(userStructArray[i], infName);
            }
        }

        individualUser memory nullUser;
        nullUser.userFirstName = "NULL"; 
        emit CreateAccount(accountWarning);
        return nullUser; 
    }
    //need a way to determine the informaiton for th
    function addUserToDataBase(string memory firstname, string memory lastname, string memory infName) public {
        require(keccak256(bytes(firstname)) != keccak256(bytes("NULL")));
        individualUser memory newUser; 
        newUser.userFirstName = firstname;
        newUser.userLastName = lastname;
        newUser.userWallet = payable(msg.sender);
        newUser.userType = 1;
        newUser.infName = infName;
        userStructArray.push(newUser);
    }

    function findInfWallet(string memory infName) private returns (infrastructure memory)  {
        for (uint i = 0; i < infStructArray.length; i++){
            if (keccak256(bytes(infName)) == keccak256(bytes(infStructArray[i].infName))) {
                return infStructArray[i];
            }
        }
        infrastructure memory NullInf; 
        NullInf.infName = "NULL";
        emit noInfFound(infNotFoundWarning);
        return NullInf; 
    }

    function findInfWalletByAddressForWithdrawal(address payable infAdd) private returns(infrastructure memory) {
        for (uint i = 0; i < infStructArray.length; i++){
            if (infStructArray[i].infWallet == infAdd) {
                return infStructArray[i];
            }
        }
        infrastructure memory NullInf; 
        NullInf.infName = "NULL";
        emit noInfFound(infNotFoundWarning);
        return NullInf; 

    }
    //depending on how much they spend their cost may become lower
    function updateUserType(individualUser memory currUser, infrastructure memory currInf) private {
        for (uint i = 0; i < userStructArray.length; i++){
            if (currUser.userWallet == userStructArray[i].userWallet) {
                require(keccak256(bytes(currUser.infName)) == keccak256(bytes(currInf.infName)));
                if (currUser.totalPayed > currInf.member_type1_threshold) {
                    currUser.userType = 2; 
                } 
                if (currUser.totalPayed > currInf.member_type2_threshold) {
                    currUser.userType = 3; 
                }
                if (currUser.totalPayed > currInf.member_type3_threshold) {
                    currUser.userType = 4; 
                }
                break;
            }
        }
    }

    function updateCurrInfRevenue(uint payed, infrastructure memory currInf) private {
         for (uint i = 0; i < infStructArray.length; i++){
            if (currInf.infWallet == infStructArray[i].infWallet) {
                infStructArray[i].totalRevenue += payed; 
                infStructArray[i].withdrawableRevenue += payed;
                break;
            }
        }
 
    }

    function getAllInfArrayItems() public {
        for (uint i = 0; i < infStructArray.length; i++){
            emit printinfArray(infStructArray[i].infName, infStructArray[i].infWallet, infStructArray[i].totalRevenue, infStructArray[i].withdrawableRevenue, infStructArray[i].totalVisits);

        }
    }

    function getAllIndUsersArrayItems() public {
        for (uint i = 0; i < userStructArray.length; i++){
            emit printIndUserArray(userStructArray[i].userFirstName, userStructArray[i].userLastName, userStructArray[i].userWallet, userStructArray[i].totalPayed, userStructArray[i].userType);
        }
    }

    function getUserCost(individualUser memory currUser, infrastructure memory currInf) private returns (uint) {
        require(keccak256(bytes(currUser.infName)) == keccak256(bytes(currInf.infName)),  "The user's infrastructure does not match the name of the infrastructure you are using..");
        if (currUser.userType == 1) {
            return currInf.member_type1_cost;
        } else if (currUser.userType == 2) {
            return currInf.member_type2_cost; 
        } else if (currUser.userType == 3) {
            return currInf.member_type3_cost;
        }
    }

    function updateUserTotalPayed(individualUser memory currUser, uint amountPayed) private {
        for (uint i = 0; i < userStructArray.length; i++){
            if (currUser.userWallet == userStructArray[i].userWallet) {
                userStructArray[i].totalPayed += amountPayed; 
            }
        }
    }

    function updateInfWithdrawableAmount(infrastructure memory currInf, uint amountWithdrawed) private {
        for (uint i = 0; i < infStructArray.length; i++){
            if (currInf.infWallet == infStructArray[i].infWallet) {
                infStructArray[i].withdrawableRevenue -= amountWithdrawed; 
            }
        }
    }


    function withdrawRevenue(uint amountToWithdraw) public {
        require(amountToWithdraw > 0, "Please enter a number greater than 0 to withdraw!");
        infrastructure memory infStruct = findInfWalletByAddressForWithdrawal(payable(msg.sender));
        require(keccak256(bytes(infStruct.infName)) != keccak256(bytes("NULL")));
        if (amountToWithdraw > infStruct.withdrawableRevenue){
            emit insufficientFunds(amountToWithdraw, infStruct.withdrawableRevenue, infStruct.infName, infStruct.infWallet);
            require(amountToWithdraw <= infStruct.withdrawableRevenue);
        } else if(amountToWithdraw <= infStruct.withdrawableRevenue) {
            infStruct.infWallet.transfer(amountToWithdraw);
            updateInfWithdrawableAmount(infStruct, amountToWithdraw);
            emit successfulWithdrawal(infStruct.infName, infStruct.infWallet, "The funds were successfully withdrawn into the infrastuctures' wallet!");
        }
    }

    function checkHowMuchIOwe(string memory infName) public {
        individualUser memory currUser = findUserInDataBase(payable(msg.sender), infName);
        infrastructure memory currInf = findInfWallet(infName); 
        require(keccak256(bytes(currUser.userFirstName)) != keccak256(bytes("NULL")), "We could not find the user!");
        require(keccak256(bytes(currInf.infName)) != keccak256(bytes("NULL")), "We could not find the current infrastructure..");
        uint userCost = getUserCost(currUser, currInf);
        emit sendCost("The amount you owe is presented below: ",  userCost);


    }

    function IndUsrpayInfrustuctureWallet(string memory infName) public payable {
        //require(msg.sender == X );
        individualUser memory currUser = findUserInDataBase(payable(msg.sender), infName);
        infrastructure memory currInf = findInfWallet(infName); 
        require(keccak256(bytes(currUser.userFirstName)) != keccak256(bytes("NULL")), "We could not find the user!");
        require(keccak256(bytes(currInf.infName)) != keccak256(bytes("NULL")), "We could not find the current infrastructure..");
        uint userCost = getUserCost(currUser, currInf);
        require(msg.value == userCost);
        updateCurrInfRevenue(msg.value, currInf);
        this.deposit(address(this));
        updateUserType(currUser, currInf);
        updateUserTotalPayed(currUser, userCost);
        emit userPaymentSuccess(userCost, currUser.userFirstName, currUser.userLastName,currInf.infName);
        }
}