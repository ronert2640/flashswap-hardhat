// pragma solidity ^0.8.3;
pragma solidity ^0.6.6;

// SPDX-License-Identifier: MIT
import '@uniswap/v2-core/contracts/interfaces/IERC20.sol';
import '@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';



//NOTE: Compiler import of different solc version
//import '@openzeppelin/contracts/token/ERC20/IERC20.sol' --> Using UniSwap Core version as with SafeMath
//import '@openzeppelin/contracts/security/ReentrancyGuard.sol'; --> TODO Reentrancy After Istanbul logic 

contract FlashSwap {
  address public Dex1Factory;
  address owner;
  uint constant deadline = 10 days;
  IUniswapV2Router02 public Dex2Router;

  constructor(address _Dex1Factory, address _Dex2Router) public {
    Dex1Factory = _Dex1Factory;  
    Dex2Router = IUniswapV2Router02(_Dex2Router);
  }

  function startFlashSwap(
    address token0, 
    address token1, 
    uint amount0, 
    uint amount1
  )  external {
    address pairAddress = IUniswapV2Factory(Dex1Factory).getPair(token0, token1);
    require(pairAddress != address(0), 'This pool does not exist');
    IUniswapV2Pair(pairAddress).swap(
      amount0, 
      amount1, 
      address(this), 
      bytes('not empty')
    );
  }

  function Dex1Call(
    address _sender, 
    uint _amount0, 
    uint _amount1, 
    bytes calldata _data
  )  external {
    address[] memory path = new address[](2);
    uint amountToken = _amount0 == 0 ? _amount1 : _amount0;
    
    address token0 = IUniswapV2Pair(msg.sender).token0();
    address token1 = IUniswapV2Pair(msg.sender).token1();

    require(
      msg.sender == UniswapV2Library.pairFor(Dex1Factory, token0, token1), 
      'Unauthorized'
    ); 
    require(_amount0 == 0 || _amount1 == 0);

    path[0] = _amount0 == 0 ? token1 : token0;
    path[1] = _amount0 == 0 ? token0 : token1;

    IERC20 token = IERC20(_amount0 == 0 ? token1 : token0);
    
    token.approve(address(Dex2Router), amountToken);

    uint amountRequired = UniswapV2Library.getAmountsIn(
      Dex1Factory, 
      amountToken, 
      path
    )[0];
    uint amountReceived = Dex2Router.swapExactTokensForTokens(
      amountToken, 
      amountRequired, 
      path, 
      msg.sender, 
      deadline
    )[1];

    IERC20 otherToken = IERC20(_amount0 == 0 ? token0 : token1);
    otherToken.transfer(msg.sender, amountRequired);
    otherToken.transfer(tx.origin, amountReceived - amountRequired);
  }

//NOTE: Requires Reentrancy Configuration
  function withdraw(uint amount) public {
    require ( msg.sender == owner );
    msg.sender.transfer(amount);
}
}
