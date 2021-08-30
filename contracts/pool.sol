// SPDX-License-Identifier: MIT
pragma solidity =0.6.10;
import "./interfaces/SafeMath.sol";
import "./interfaces/ERC20.sol";

contract pool {
    using SafeMath  for uint;

    address public token1;
    address public token2;
    address public owner;

    //_flateRate = token1Amount/token2Amount
    uint256 private _flatRate;
    uint256 private _curRate;
    uint256 private timeStamp;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    constructor(address _token1, address _token2, 
        uint256 flatRate) public{
        token1= _token1;
        token2= _token2;
        owner= msg.sender;
        _flatRate= flatRate;
        timeStamp=now;
    }

    //Help functions
    function _safeTransfer(address token, address to, uint256 value)private{
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length ==0 || abi.decode(data, (bool))), 
        "token transfer failed");
    }


    //Modifiers
    modifier rateCheck(){
        uint256 fluctuation = _flatRate.mul(2).div(100);
        require(_flatRate.sub(fluctuation) <  _curRate &&  _curRate < _flatRate.add(fluctuation),
        "price overflow");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "only owner can do this operaiton");
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

    function retrieveLiquidity(uint256 token1amount) public onlyOwner {
        require(now > timeStamp + 5 days, "you need to wait for 5 days until next retrieve operation");
        _safeTransfer(token1, owner, token1amount);
        _safeTransfer(token2, owner, token1amount.mul(_curRate));
        timeStamp=now;
        }


    function swap(uint256 token1amount, uint256 token2amount)public rateCheck{
        require(token1amount ==0 || token2amount==0, 
        "You can only input one token");
        (uint256 _reserve1, uint256 _reserve2) = getReserves(); 
        uint256 k_origin = _reserve1.mul(_reserve2);
        uint256 k_aug = k_origin.mul(100);

        //Make sure which is the input token
        bool token1Input = token1amount !=0 ? true : false;
        if(token1Input){
            require(ERC20(token1).transferFrom(msg.sender, address(this),token1amount));
            uint256 token2Output = k_aug.div(_reserve1.add(token1amount)).sub(_reserve2);
            //rateCheck
            uint256 _curRateTempt = (_reserve1.add(token1amount)).div(_reserve2.sub(token2Output));
            require(_flatRate.mul(98).div(100) <  _curRateTempt &&  _curRateTempt < _flatRate.mul(102).div(100),
                    "Rate is unbalanced after swap. SWAP FAILED");
            _safeTransfer(token2, msg.sender, token2Output);

        }
        else{
            require(ERC20(token2).transferFrom(msg.sender, address(this),token2amount));
            uint256 token1Output = k_aug.div(_reserve2.add(token2amount)).sub(_reserve1);
             //rateCheck
            uint256 _curRateTempt = (_reserve1.sub(token1Output)).div(_reserve2.add(token2amount));
            require(_flatRate.mul(98).div(100) <  _curRateTempt &&  _curRateTempt < _flatRate.mul(102).div(100),
                    "Rate is unbalanced after swap. SWAP FAILED");
            _safeTransfer(token1, msg.sender, token1Output);
        }
    }
  

}
