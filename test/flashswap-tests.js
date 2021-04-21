const { expect } = require("chai");

describe("FlashSwap", function() {
  it("Should start FlashSwap, Call Dex1 and withdraw profits", async function() {

    const FlashSwap = await ethers.getContractFactory("FlashSwap");
    //Deploy the smart contract
    const flashswap = await FlashSwap.deploy("0xBCfCcbde45cE874adCB698cC183deBcF17952812", "0xCDe540d7eAFE93aC5fE6233Bee57E1270D3E330F");
    
    await flashswap.deployed();

    //call startArbitrage
    expect(await flashswap
                  .startFlashSwap( 
                    "address token0", 
                    "address token1", 
                    "uint amount0", 
                    "uint amount1"))
                  .to.equal("Hello, world!");

    //call pancakeCall
    expect(await arbitrage
                  .Dex1Call( 
                    "address _sender", 
                    "uint _amount0", 
                    "uint _amount1", 
                    "bytes calldata _data"))
                  .to.equal("Hello, world!");

    //Call withdraw
    expect(await arbitrage
      .withdraw())
      .to.equal("Hello, world!");
                  
  });
});
