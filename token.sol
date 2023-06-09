// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    struct Staker {
        uint256 amount;
        uint256 startTimestamp;
        uint256 lastRewardTimestamp;
        uint256 accumulatedReward;
    }

    mapping(address => Staker) private _stakers;
    address[] private _stakerAddresses;

    uint256 private constant REWARD_RATE = 10; // Reward rate in percentage (e.g., 10%)
    uint256 private constant MIN_STAKING_DURATION = 1 days;

    uint256 private _rewardPool;

    event Staked(address indexed account, uint256 amount, uint256 startTimestamp);
    event Unstaked(address indexed account, uint256 amount, uint256 duration, uint256 reward);

    constructor(string memory name, string memory symbol)
        ERC20(name, symbol)
    {
        _mint(msg.sender, 1000000 * 10**decimals());
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(
            balanceOf(msg.sender) >= amount,
            "Insufficient balance for staking"
        );

        _transfer(msg.sender, address(this), amount);

        Staker storage staker = _stakers[msg.sender];
        staker.amount += amount;
        staker.startTimestamp = block.timestamp;
        staker.lastRewardTimestamp = block.timestamp;

        if (staker.amount == amount) {
            _stakerAddresses.push(msg.sender);
        }

        emit Staked(msg.sender, amount, block.timestamp);
    }

    function unstake() external {
        Staker storage staker = _stakers[msg.sender];
        require(staker.amount > 0, "No stake found");

        require(
            block.timestamp >= staker.startTimestamp + MIN_STAKING_DURATION,
            "Minimum staking duration not reached"
        );

        uint256 reward = calculateReward(staker.amount, staker.lastRewardTimestamp);
        uint256 totalAmount = staker.amount + reward;

        staker.amount = 0;
        staker.lastRewardTimestamp = block.timestamp;

        _transfer(address(this), msg.sender, totalAmount);

        emit Unstaked(msg.sender, staker.amount, block.timestamp - staker.startTimestamp, reward);
    }

    function calculateReward(uint256 stakedAmount, uint256 lastRewardTimestamp)
        internal
        view
        returns (uint256)
    {
        uint256 stakingDuration = block.timestamp - lastRewardTimestamp;
        uint256 reward = (stakedAmount * REWARD_RATE * stakingDuration) / MIN_STAKING_DURATION;
        return reward;
    }

    function distributeRewards() external {
        require(_rewardPool > 0, "Reward pool is empty");

        uint256 totalReward = _rewardPool;
        _rewardPool = 0;

        uint256 totalStakedAmount;

        for (uint256 i = 0; i < _stakerAddresses.length; i++) {
            address account = _stakerAddresses[i];
            Staker storage staker = _stakers[account];

            if (staker.amount > 0) {
                uint256 reward = calculateReward(staker.amount, staker.lastRewardTimestamp);
                staker.accumulatedReward += reward;
                totalStakedAmount += staker.amount;
            }
        }

        if (totalStakedAmount > 0) {
            uint256 remainingReward = totalReward;
            for (uint256 i = 0; i < _stakerAddresses.length; i++) {
                address account = _stakerAddresses[i];
                Staker storage staker = _stakers[account];

                if (staker.amount > 0) {
                    uint256 accountReward = (staker.accumulatedReward * totalReward) / totalStakedAmount;
                    staker.accumulatedReward -= accountReward;
                    remainingReward -= accountReward;
                    _transfer(address(this), account, accountReward);
                }
            }

            // Transfer any remaining reward to the reward pool for the next distribution
            _rewardPool = remainingReward;
        } else {
            // If there are no stakers, transfer the total reward back to the reward pool
            _rewardPool = totalReward;
        }
    }

    function addToRewardPool(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(
            balanceOf(msg.sender) >= amount,
            "Insufficient balance to add to the reward pool"
        );

        _transfer(msg.sender, address(this), amount);
        _rewardPool += amount;
    }

    function getStakedBalance(address account) public view returns (uint256) {
        return _stakers[account].amount;
    }

    function getStakingStartTimestamp(address account) public view returns (uint256) {
        return _stakers[account].startTimestamp;
    }

    function getAccumulatedReward(address account) public view returns (uint256) {
        return _stakers[account].accumulatedReward;
    }
}
