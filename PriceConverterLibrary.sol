// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./AggregatorV3Link.sol";

library PriceConverterLibrary
{
    function getTotalValue(uint ethAmount) internal view returns(uint256,uint8,uint256,uint256) 
    {
        AggregatorV3Link chainOracle= AggregatorV3Link(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        uint256 ethPrice= uint256(getPrice()); //This function is view as the local variables are not stored on the blockchain and are only available till function execution, hence the state of the blockchain is not being changed
        //If this function would have changed the state of a state variable, then it would not be a view only function

        //Here, the decimals and formattedPrice are also declared in the global field and now also returned here, solidity will return the local variables here and not the global variable with the same name, to return the global variable, use this.globalVar instead
        uint8 decimals= chainOracle.decimals();
        uint256 formattedPrice= ethPrice/10** decimals;
        uint256 totalVal= ethAmount*formattedPrice;
        
        return(ethPrice,decimals,formattedPrice,totalVal);
    }

        function getPrice()  internal view returns( int256)
    {
        AggregatorV3Link chainOracle= AggregatorV3Link(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (,
        int answer,
        /*uint256 num3*/,
        /*uint256 num4*/,
        /*uint80 num5*/)= chainOracle.latestRoundData();
        return (answer);
    }




}