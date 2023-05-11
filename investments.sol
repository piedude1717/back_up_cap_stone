pragma solidity >=0.7.0 <0.9.0;

contract Lending { 
    struct individualInvestor {
        address payable InvestorAddress;
        attachedInfratructure attachedInf;
        uint totalAmountInvested;
        uint ownedEquityPerc; 
    }

    struct contractor {
        address payable contractorAddress;
        attachedInfratructure attachedInf;
    }

    struct attachedInfratructure {
        invdividualInvestor[]: investors, 
        cotractor[] contractors, 
        infrastructureId, 
        uint: totalInvestmentPrincipleValue,
        uint: totalRevenueGeneratedFromInf, 
        uint: withdrawableFunds, 
        uint: withdrawedFunds, 
        uint: currentFunds, 
        uint: totalTokensReleased

    }
    constructor()  {
            owner = msg.sender;
        }


    function deposit(address walletAddress) payable public {}

    function sellEquity(uint: percToSell) {}

    function buyEQuity(uint: percToBuy) {}

    function checkEquityValue() public returns(uint) {}

    function withdrawFunds(uint amountToWithdraw) public() {}
    
    function getTotalREvenueGenerated() public {}

    function getTotalInvestmentPrincipleValue() public {}

    function getAllInvestors() {}

    function getAllContractors() {}





}