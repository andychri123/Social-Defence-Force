pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./Token.sol";



contract Crowdsale is Owned, Token {

    using SafeMath for uint256;  
    address payable fundWallet;
    address payable myWallet;
    uint256 public WEI_DECIMALS = 10**18;
    uint256 public ethUSD = 1100;
    uint256 public price;
    //@dev global count for the number of buyers
    uint256 public count;
    uint256 public AVG_NUM_INVESTORS = 10000;
    address payable self = address(this);
    uint256 balance = self.balance;

    constructor() public {
        count = 0;
    //    address payable token = Token();
        myWallet = 0x5bce20B5D249a463e38D0F9E8D00Ee28fb64ea0C;
        fundWallet = 0x24bbAC12c57c0df516BF53a283F10B846BDab689;
    }

    // ------------------------------------------------------------------------
    // Do accept ETH
    // ------------------------------------------------------------------------

    function () external payable {
        buyTokens();
    }

    //-------------------------------------------------------------------------
    // Buy Token
    //-------------------------------------------------------------------------
    function buyTokens() public payable {
        //require(_buyer != 0x0);
        uint256 weiAmount = msg.value;
        uint256 tokens = calculateTokens(weiAmount);
        mint(msg.sender, tokens);
        _forwardFunds();
    }

    //-------------------------------------------------------------------------
    // Calculate the amount of tokens the buyer can purchase
    // based on the eth sent and how many other people bought before.
    // Token price increases each time this function is called.
    // @param _weiAmount is the amount of wei/eth the buyer sent 
    //-------------------------------------------------------------------------

    function calculateTokens(uint256 _weiAmount) internal returns (uint256)
    {
        uint256 tokens = _weiAmount.div(priceOf());
        assert(tokens != 0);
        return tokens;
    }
    /// at $0.007 cap at $0.07 10000 average investors not allow same buyer to drive up the price
    /// @notice this function is set up to calculate the price of the tokens on a sliding scale. 
    /// incremented each time the buy function is executed.
    /// @dev verify etherPrice before purhing the contract live.
    /// @dev confirm the averageNumInvestors of 5000 is acceptable.

    function priceOf() internal returns (uint256){
        uint256 maxTokenPrice = WEI_DECIMALS.div(100).mul(7); //max price $0.07 USD per token multiplied by wei early to avoid truncation by division.
        uint256 minTokenPrice = WEI_DECIMALS.div(1000).mul(7); //min price $0.007 USD per token multiplied by wei early to avoid truncation by division.
        uint256 minWeiPerToken = minTokenPrice.div(ethUSD);
        uint256 maxWeiPerToken = maxTokenPrice.div(ethUSD);
        uint256 increments = (maxWeiPerToken.sub(minWeiPerToken)).div(AVG_NUM_INVESTORS); 
        price = minWeiPerToken.add(increments.mul(count));
        if (price > maxWeiPerToken) {
            price = maxWeiPerToken;
        }
        assert(price != 0);        
        return price;
    }

    function setEthUSD(uint _rate) public onlyOwner {

        require(_rate > 0);
        ethUSD = _rate;
    }

    function allowOnce(address _buyer) internal returns (uint256) {

        if(Token.balanceOf(_buyer) == 0){
            count++;
        }
        return count;
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function getPercent(uint _percent, uint _ofNum) public pure returns(uint percent) {
        uint numerator = _percent.mul(1000);
        require(numerator > _percent); // overflow. Should use SafeMath throughout if this was a real implementation.
        uint temp = numerator.div(_ofNum).add(5); // proper rounding up
        return temp.div(10);

    }

    function _forwardFunds() internal {
        if (msg.value > 0){
          uint five = getPercent(5, msg.value);
        // msg.value - received ethers
        transferFrom(self, myWallet, five);
        transferFrom(self, fundWallet, balance);
                // address(this).balance - 
                //contract balance after transaction to MY_ADDRESS (half of received ethers)
                }
            }
        
        //    function withdraw() public onlyOwner {
        //        wallet.transfer(this.balance);
        //    })
//    function setFundWallet(address payable _fundWallet) public onlyOwner {
//        address payable fundWallet = _fundWallet;        
//    }
//    function setMyWallet(address payable _myWallet) public onlyOwner {
//       address payable myWallet = _myWallet;        
//    }
    
}