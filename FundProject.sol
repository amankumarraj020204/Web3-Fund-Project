//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PriceConverterLibrary.sol";
import "./AggregatorV3Link.sol";

//ORACLES AND CHAINLINKS
//We use a decentralized oracle network to get the price of 1 ETH in USD
//Chainlink is the decentralized oracle network

error NotOwner();


contract Fundme
{

    using PriceConverterLibrary for uint256;

        //GAS EFFICIENCY COURSE:


    //constant, immutable (Brings down the deployent gas)
    //constant is used for the vars which are declared and initialized in the same line for once and all
    //immutable is used for the vars which are declared and initialized in different lines, specially within a function, it can only be set once;


    //The require statements, in the error statement section, contract has to store each character as an array and this costs gas
    //To get rid of this, we use revert using if-else and this saves gas


    AggregatorV3Link chainOracle;

    int public constant CONST_NUM= 11; 
    int public immutable i_Var;

    int public minimumUSD=50;
    mapping(address=> uint256) public ethFunded;
    address[] public funders;

    address payable public immutable i_deployerAddress;

    address payable public contractAddress;
    int public currentPrice;
    uint256 public formattedPrice;
    uint8 public decimals;
    int public ethVal;
    mapping(address=> uint256) public fundCount;

    modifier onlyDeployer
    {
        if(msg.sender != i_deployerAddress)
        {
            revert NotOwner();
        }
        _;
    }

    constructor()
    {
        chainOracle= AggregatorV3Link(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        i_deployerAddress= payable(msg.sender);
        currentPrice=0;
        contractAddress= payable(address(this));
    }

    function setPriceOracle(address oracleAddress) public onlyDeployer
    {
        chainOracle= AggregatorV3Link(oracleAddress);
    }

    function checkVals() public view returns(uint256,int)
    {
        uint ethVal= (50*10**8)* 10**18/(uint(1900)*(10**8));
        int answer=PriceConverterLibrary.getPrice();
        return (ethVal,answer);
    }

    function fundUSD() payable public 
    {
        (uint256 DecPrice,uint8 deci,uint256 curPrice,)= uint256(1).getTotalValue(); //Returns both, the decimals included price and fromatted
        uint256 eth_recent_Price= DecPrice/10**deci;
        //Let the decimals base be 10^3
        //uint256 eth_recent_Price=1900;
        require((msg.value*eth_recent_Price)/10**18>=uint256(minimumUSD),"The fund value must be greater than 50 USD in ETH");
        ethFunded[msg.sender]+=msg.value;
        funders.push(msg.sender);
        fundCount[msg.sender]++; 

    }

    function fetchDetails() public view returns(string memory)
    {
        return "Hello, I am fetched";
    }

    function fundWEI() payable public
    {
        //require if not met reverts and sends back all the extra remaining gas back
        (uint256 oracleFeed,,,)= uint256(1).getTotalValue();
        ethVal= (minimumUSD*10**8)*10**18/int(oracleFeed);
        //ethVal= (minimumUSD*10**8)*10**18/int(1900*(10**8)); //Convert these to wei
        require(msg.value>= uint256(ethVal),"Value should be more than 50 USD in ETH");
        ethFunded[msg.sender]+=msg.value;
        funders.push(msg.sender);
        fundCount[msg.sender]++;
    }

    function formatPrice() public 
    {
        decimals= chainOracle.decimals();
        (,int answer,,,)= chainOracle.latestRoundData();
        currentPrice= answer;
        formattedPrice= (uint256(answer)/(10** decimals));
    }


    function setPrice() public 
    {
        (,int answer, ,,)= chainOracle.latestRoundData(); //Taking all the return parameters and then storing the required one in the variable to work upon
        currentPrice= answer;
    }

    function getVersion() public view returns(uint256)
    {
        return chainOracle.version();
    }

    function getDecimals() public view returns(uint)
    {
        return chainOracle.decimals();
    }

    function getDescription() public view returns(string memory)
    {
        return chainOracle.description();
    }

    function isFunder(address _checkAdd) public view returns(bool)
    {
        return (fundCount[_checkAdd]==0) ? false : true;
    }

    

    function withdraw() public onlyDeployer
    {

        for(uint256 i=0;i<funders.length;i++)
        {
            ethFunded[funders[i]]=0;
            fundCount[funders[i]]=0;
            //funders[0]=address(0);  //Either iterate through the array elements and make them null or simply make the whole array resetted;
        }

        funders= new address[](0); //Resets the complete array with 0 elements now.

        //ETH can be sent from contract via three methods,
        //transfer, send and call
        //transfer revert the transaction if the sending is failed with the error message
        //send doesn't rever the transaction if the sending fails instead, returns a bool for transaction status
        //call is the way of universally calling any method within Ethereum
        
        /*
        
        "transfer"

        uint256 balance= contractAddress.balance;
        deployerAddress.transfer(balance);

        */

        /*

            send 

        bool sendSucess= deployerAddress.send(address(this).balance);
        require(sendSuccess,"Sending was not through");

        */

        (bool callSuccess, bytes memory dataReturned)= payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess,"Call transfer failed, reverted");

    }



    receive() external payable { 
        fundUSD();
    }

    fallback() external payable {
        fundUSD();
     }

    //receive only receives the eth with no calldata
    //if there is a call data, error will be triggered and for that to work, fallback is required.

}