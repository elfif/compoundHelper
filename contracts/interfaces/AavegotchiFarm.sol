pragma solidity 0.8.13;
import './IERC20.sol';

interface AavegotchiFarm {

  struct UserInfoOutput {
    IERC20 lpToken; // LP Token of the pool
    uint256 allocPoint;
    uint256 pending; // Amount of reward pending for this lp token pool
    uint256 userBalance; // Amount user has deposited
    uint256 poolBalance; // Amount of LP tokens in the pool
  }

  function allUserInfo(address _user)
    external view 
    returns (UserInfoOutput[] memory);

} 