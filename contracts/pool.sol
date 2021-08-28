// SPDX-License-Identifier: MIT
pragma solidity =0.6.10;
import "./interfaces/SafeMath.sol";
import "./interfaces/ERC20.sol";

contract pool {
    using SafeMath  for uint;

    address public token1;
    address public token2;
    address public owner;

    uint256 private _flatRate;
    uint256 private _curRate;
    uint32  private timeStamp;


    constructor(address _token1, address _token2, 
        uint256 flatRate) public{
        token1= _token1;
        token2= _token2;
        owner= msg.sender;
        _flatRate= flatRate;
    }

    //Modifiers
    modifier rateCheck( ){
        uint256 fluctuation = _flatRate.mul(2).div(100);
        require(_flatRate.sub(fluctuation) <  _curRate &&  _curRate < _flatRate.add(fluctuation),
        "price overflow");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "only owner can do this operaiton");
        _;
    }

    modifier timelock(){
        require(now > timeStamp + 5 days, "you need to wait for 5 days until next retrieve operation");
        _;
    }

    //view functions
    function getReserves()public view returns(uint256 _token1Reserve, uint256 _token2Reserve){
        _token1Reserve= ERC20(token1).balanceOf(address(this));
        _token2Reserve= ERC20(token2).balanceOf(address(this));
    }

    //actions
    function addLiquidity(uint256 token1amount)public onlyOwner{
    require(ERC20(token1).transferFrom(msg.sender, address(this),token1amount), 
        "Not the right token1 amount");
    uint256 token2amount = token1amount.mul(_curRate);
    require(ERC20(token2).transferFrom(msg.sender, address(this),token2amount), 
        "Not the right token2 amount");


    }
  

}
