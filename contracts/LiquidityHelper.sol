// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Router01.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

struct CompoundArgsStruct {
    address token;
    uint8 balancePercentage; // Percentage of his balance that msg.sender agrees to transfer
}

struct BalanceStruct {
    address token;
    uint256 balance;
}

contract LiquidityHelper {

    using SafeMath for uint;

    error LengthMismatch();
    IUniswapV2Router01 router;
    address GHST;
    address owner;
    //0--fud 1--fomo 2--alpha 3--kek 4--GLTR
    address[2][5] tokensAndLps;
    
    constructor(
        // First level is one item per alchemica + GLTR = 5 items
        // Second level is [token address, quickswap GHST / other token lp token address]
        address[2][5] memory _tokensAndLps, 
        address _routerAddress,
        address _ghst,
        address _owner
    ) {
        //approve ghst to be send to the router
        IERC20(_ghst).approve(_routerAddress, type(uint256).max);
        // approve alchemicas, GLTR and lp tokens 
        for (uint256 i; i < _tokensAndLps.length; i++) {
            // Approve that the contract can send main token to the router
            require(
                IERC20(_tokensAndLps[i][0]).approve(
                    _routerAddress,
                    type(uint256).max
                )
            );
            // Approve that the contract can send related lp token to the router
            require(
                IERC20(_tokensAndLps[i][1]).approve(
                    _routerAddress,
                    type(uint256).max
                )
            );
        }

        router = IUniswapV2Router01(_routerAddress);
        GHST = _ghst;
        tokensAndLps = _tokensAndLps;
        owner = _owner;
    }

    function swapAndCoumpound(CompoundArgsStruct[] memory param) public returns (uint256[11] memory response) {
        // For each alchemica + GLTR as token
        // We swap half param percentage of token in GHST
        // Then we will add to GHST / token pool the amount of GHST we swapped + needed amount of token 
        // Then we transfer back the lp tokens to msg.sender

        require(param.length == 5);
        uint256 minAmount = 100000000000000000;
        
        for (uint256 i; i < param.length; i++) {
            require(param[i].balancePercentage > 0 && param[i].balancePercentage <= 100, "Percentage must be > 0 && <= 100");
            uint256 amountToTransfer = IERC20(param[i].token).balanceOf(msg.sender).mul(param[i].balancePercentage).div(100);
            // #if DEV_MODE==1
            console.log("Alchemica", param[i].token, "Total Balance", IERC20(param[i].token).balanceOf(msg.sender));
            console.log("Alchemica", param[i].token, "To transfer", amountToTransfer);
            // #endif
            require(amountToTransfer <= IERC20(param[i].token).balanceOf(msg.sender));
            IERC20(param[i].token).transferFrom(msg.sender, address(this), amountToTransfer);
            // #if DEV_MODE==1
            console.log('first transfer is done');
            // #endif
            // I set % at 52 instead of 50 to secure 2 things
            // * Be sure i will spend all alchemicas transfered initially
            // * Have a quantity of GHST to transfer back to tyhe sender when all isdone
            address[] memory path = new address[](2);
            path[0] = param[i].token;
            path[1] = GHST;
            // #if DEV_MODE==1
            console.log('before router call');
            // #endif
            uint256[] memory amounts = router.swapExactTokensForTokens(
                amountToTransfer.mul(52).div(100),
                minAmount,
                path,
                address(this),
                block.timestamp + 3000
            );
            // #if DEV_MODE==1
            console.log('swap is done', amounts[0], amounts[1]);
            console.log('Start adding liquidity');
            // #endif
            // Get the balance of alchemica remaining in the contract
            uint256 alchemicaToAdd = IERC20(param[i].token).balanceOf(address(this));
            // Ask the router how much GHST i could get for it. It is my way to know how much GHST i wiull try to add to the pool
            uint ghstToAdd = router.getAmountsOut(alchemicaToAdd, path)[1].mul(1004).div(1000);
            // #if DEV_MODE==1
            console.log("token A to be added", alchemicaToAdd);
            console.log("token B to be added", ghstToAdd);
            // #endif
            // Check if the optimal GHST amount is <= to my GHST balance 
            require(ghstToAdd <= amounts[1]);
            // (uint amount0, uint amount1, uint amountLp) = router.addLiquidity(
            (uint amountA , uint amountB, uint amountLp) = router.addLiquidity(
                param[i].token,
                GHST,
                alchemicaToAdd,
                ghstToAdd,
                alchemicaToAdd - alchemicaToAdd.div(100).mul(3),
                ghstToAdd - ghstToAdd.div(100).mul(3),
                address(this),
                block.timestamp + 3000
            );
            // #if DEV_MODE==1
            console.log('Finished adding liquidity');           
            console.log("token A added", amountA);
            console.log("token B added", amountB);
            // #endif
            IERC20 lpToken = IERC20(tokensAndLps[i][1]);
            // #if DEV_MODE==1
            console.log("Balance Lp", lpToken.balanceOf(address(this)));
            // #endif
            lpToken.approve(msg.sender, amountLp);
            lpToken.transfer(msg.sender, amountLp);
            response[i] = amountLp;

            if (IERC20(param[i].token).balanceOf(address(this)) > 0) {
                // This case is the one we want to avoid because of how much extra gas it is.....
                IERC20(param[i].token).transfer(msg.sender, IERC20(param[i].token).balanceOf(address(this)));
                // #if DEV_MODE==1
                console.log("Remaining alchemica dust to transfer back....", param[i].token, IERC20(param[i].token).balanceOf(address(this)));
                // #endif
                response[i.add(6)] = IERC20(param[i].token).balanceOf(address(this));
            }
        }

        // Loop is done all tokens sent back except GHST 
        // Time to transfer remainings back
        if (IERC20(GHST).balanceOf(address(this)) > 0) {
            IERC20(GHST).transfer(msg.sender, IERC20(GHST).balanceOf(address(this)));
            // #if DEV_MODE==1
            console.log("Final GHST traansfer back to sender", IERC20(GHST).balanceOf(address(this)));
            // #endif
            response[6] = IERC20(GHST).balanceOf(address(this));
        }       

        return response;
    }

    function getAllBalances() public view returns (BalanceStruct[] memory) {
        // #if DEV_MODE==1
        console.log("msg.sender = ", msg.sender);
        console.log("tokensAndLps.length", tokensAndLps.length);
        console.log("tokensAndLps[0].length", tokensAndLps[0].length);
        // #endif
        uint size = 10;
        BalanceStruct[] memory balances = new BalanceStruct[](size);
        uint8 balancesIndex = 0;

        // Get balances of all alchemicas
        for (uint256 i; i < tokensAndLps.length; i++) {
            // Main token balance
            BalanceStruct memory balanceToken = BalanceStruct(
                tokensAndLps[i][0],
                IERC20(tokensAndLps[i][0]).balanceOf(msg.sender)
            );
            balances[balancesIndex] = balanceToken;
            balancesIndex++;

            BalanceStruct memory balanceLpToken = BalanceStruct(
                tokensAndLps[i][1],
                IERC20(tokensAndLps[i][1]).balanceOf(msg.sender)
            );
            balances[balancesIndex] = balanceLpToken;
            balancesIndex++;
        }
        return balances;
    }
}