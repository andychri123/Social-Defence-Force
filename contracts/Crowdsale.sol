pragma solidity ^0.5.0;
import './Token.sol';
import './Owned.sol';

contract Crowdsale is Owned{
    //using SafeMath for uint256;

    constructor(Token _token) public {
        rate = 100;
        on = true;
        token = Token(_token);
        wallet = msg.sender;
    }
    // Token contract address 
 //   address ad = 0xBd7a60F479482088c4C16c1e95285a6D885C7698;
    Token public token;
    address payable wallet;
    uint public rate;
    bool on;

    event TokenPurchase(address recipient, uint numPaid, uint numTokensPurchased);

    function buyTokens() public payable {
        // Define a uint256 variable that is equal to the number of wei sent with the message.
        //require(msg.sender != address(0));
        require(msg.value > 0 && on == true);
        uint tokenAmount = _getTokenAmount(msg.value);
        require(token.balanceOf(address(this)) >= tokenAmount);
        token.transfer(msg.sender, tokenAmount);
        wallet.transfer(msg.value);
        emit TokenPurchase( msg.sender, msg.value, tokenAmount);
    }
    
    function () external payable{
        buyTokens();
        //test();
    }


    function _getTokenAmount(uint weiVal) public view returns (uint h) {
        uint h = weiVal * rate;
        return h;
    }

  //  function withdraw(){
//        address(this) address(wallet), address(this).balance);m,,m
    //    uint GAS_LIMIT = 4000000;
    //    wallet.call.value(address(this).balance).gas(GAS_LIMIT)("");
    //    wallet.transfer(address(this).balance);
    //}

    function test() public view returns(uint f){
        uint f = token.balanceOf(address(this));
        return f;
    }

// onlyOwoner
    function pause()public payable onlyOwner{
        on = false;
    }

// onlyOwner
    function start() public payable onlyOwner{
        on = true;
    }

    function setRate(uint _rate) public payable onlyOwner{
        rate =  _rate;
    }
}