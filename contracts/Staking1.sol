// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Array {
    /**
    *   @notice remove given elements from array
    *   @dev usable only if _array contains unique elements only
     */
    function removeElement(uint256[] storage _array, uint256 _element) public {
        for (uint256 i; i<_array.length; i++) {
            if (_array[i] == _element) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                break;
            }
        }
    }
}

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}



contract Staking1 is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Array for uint256[];

    IERC20 public METAKEY;
    IERC20 public METAWORTH;
    uint256 rewardAmount = 0;
    uint256 rewardPeriod = 5 minutes;
    uint256 public myAllowance;
    
    struct Staked {
        address owner;
        uint256 beginTime;
        uint256[] claimTime;
        uint256 amount;
        bool isExpired;
        uint256 claimRewardAmount;
        uint256 periodType;
    }
    uint256[] public periodTypes=[5 minutes, 90 days, 180 days, 365 days];

    Staked public stakedTest ;
    Staked public unstakedTest ;
    Staked public claimStaked ;
    uint256 public totalStaked;
    
    mapping (address => Staked[]) public totalStakedArray;
    uint256[] public stakingIDArr;
    address _mtw;
    address _mtwk;
    Counters.Counter private _totalStakedCount;

    constructor(address _stakingToken, address _rewardToken) {
	    _mtw = _stakingToken;
        _mtwk = _rewardToken;
        totalStaked = 0;
        METAWORTH = IERC20(_mtw);
        METAKEY = IERC20(_mtwk);
	}

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function withdraw (address _owner, uint256 _amount) public onlyOwner {
        uint256 balance = METAKEY.balanceOf(address(this));
        require(balance > 0 , "There is no METAKEY tokens");
        require(balance >= _amount , "Balance is not enough.");
        METAKEY.transfer(_owner, _amount);
    }

    function _stake(address _user, uint256 _amount, uint256 _period) internal {
        
        uint256 blockTimeStamp = block.timestamp;
        uint256 currentTimeStamp = blockTimeStamp.mul(1000);
        stakedTest.owner = _user;
        stakedTest.beginTime = currentTimeStamp;
        stakedTest.amount = _amount;
        stakedTest.isExpired = false;
        stakedTest.periodType = periodTypes[_period];
        stakedTest.claimRewardAmount = 0;
        totalStakedArray[_user].push(stakedTest);
        totalStaked = totalStaked + _amount;
        METAWORTH.transferFrom(_user, address(this), _amount * 10 ** 18 ); 
    }

    function _unstake(address _user, uint256 _stakeId) internal {
        unstakedTest = totalStakedArray[_user][_stakeId];
        totalStaked = totalStaked - unstakedTest.amount;    
        METAWORTH.transfer(_user, unstakedTest.amount * 10 ** 18);
        if(totalStakedArray[_user].length > 1){
            for(uint i = _stakeId; i < totalStakedArray[_user].length-1; i ++) {
                totalStakedArray[_user][i] = totalStakedArray[_user][i+1];
            }
        }
        totalStakedArray[_user].pop();
    }
  
    function getStakebyAddress (address _makerAdd) public view returns( Staked[] memory){
        return totalStakedArray[_makerAdd];
    }

    function getCurrentTime () public view returns( uint256){
        uint256 blockTimeStamp = block.timestamp;
        uint256 currentTimeStamp = blockTimeStamp.mul(1000);
        return currentTimeStamp;
    }

    function getStakedAmount(uint256 _stakeId) public view returns(uint256) {
        Staked storage stakedDetail = totalStakedArray[msg.sender][_stakeId];
        require(msg.sender == stakedDetail.owner, "You can't see this Info");
        uint256 stakedAmount = stakedDetail.amount;
        return stakedAmount;
    }

    function stake(address _owner, uint256 _stakingamount, uint256 _period) public {
        uint256 balance = METAWORTH.balanceOf(msg.sender);
        require(balance > 0 , "Please buy MTW tokens");
        require(balance >= _stakingamount , "Balance is not enough.");
        _stake(_owner, _stakingamount, _period);
    }

    function unstaking(uint256 _stakeId) public {
        Staked storage unstake = totalStakedArray[msg.sender][_stakeId];
        require(msg.sender == unstake.owner, "You can't unstake this");
        _unstake(msg.sender, _stakeId);
    }

    function claim(uint256 _stakeId) public {
        claimStaked = totalStakedArray[msg.sender][_stakeId];
        uint256 amount = claimStaked.amount * 10 ** 18;
        uint256 claimableReward;
        uint256 blockTimeStamp = block.timestamp;
        uint256 currentTimeStamp = blockTimeStamp.mul(1000);
        claimableReward = amount.div(1000);
        METAKEY.transfer(claimStaked.owner, claimableReward);
        totalStakedArray[msg.sender][_stakeId].claimRewardAmount = claimableReward;
        totalStakedArray[msg.sender][_stakeId].claimTime.push(currentTimeStamp);
    }   
}