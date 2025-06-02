// SPDX-License-Identifier: MIT

// Staking Contract

// Allow players to stake $BOSS tokens to earn rewards. - Locking tokens, Claiming rewards, Withdraw after unlock 7 days

pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC20.sol";

contract FlappyStaking is Ownable, Pausable {
    IERC20 public bossToken;
    address public fee_wallet;
    uint256 public STAKING_FEE; // 2% fee
    uint256 public UNLOCK_FEE; // 2% fee
    uint256 public REWARD_RATE; // 1000 $BOSS per 1M staked daily
    uint256 public UNLOCK_PERIOD;

    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        uint256 claimedRewards;
        uint256 unlockTime;
    }

    mapping(address => StakeInfo) public stakes;

    event Staked(address indexed user, uint256 amount);
    event Unlocked(address indexed user);
    event RewardsClaimed(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event FeeWalletUpdated(address wallet, uint256 timestamp);
    event UnlockPeriodUpdated(uint256 period, uint256 timestamp);
    event RewardRateUpdated(uint256 rate, uint256 timestamp);
    event FeesUpdated(uint256 stakingFee, uint256 unlockFee, uint256 timestamp);

    constructor(address _bossToken, address _feeWallet) Ownable(msg.sender) {
        bossToken = IERC20(_bossToken);
        fee_wallet = _feeWallet;
        STAKING_FEE = 2;
        UNLOCK_FEE = 2;
        REWARD_RATE = 1000;
        UNLOCK_PERIOD = 7 days;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");

        uint256 fee = (amount * STAKING_FEE) / 100;
        uint256 stakedAmount = amount - fee;

        bossToken.transferFrom(msg.sender, address(this), stakedAmount);
        bossToken.transferFrom(msg.sender, fee_wallet, fee);

        stakes[msg.sender].amount += stakedAmount;
        stakes[msg.sender].startTime = block.timestamp;

        emit Staked(msg.sender, stakedAmount);
    }

    function unlock() external {
        require(stakes[msg.sender].amount > 0, "No active stake");

        uint256 fee = (stakes[msg.sender].amount * UNLOCK_FEE) / 100;

        bossToken.transferFrom(address(this), fee_wallet, fee);

        stakes[msg.sender].amount -= fee;
        stakes[msg.sender].unlockTime = block.timestamp + UNLOCK_PERIOD;

        emit Unlocked(msg.sender);
    }

    function getClaimableRewards() external view returns (uint256) {
        StakeInfo storage stakeInfo = stakes[msg.sender];
        require(stakeInfo.amount > 0, "No active stake");

        uint256 timeStaked = block.timestamp - stakeInfo.startTime;
        uint256 reward = (stakeInfo.amount / 1_000_000) *
            REWARD_RATE *
            (timeStaked / 1 days);
        
        return reward;
    }

    function claimRewards() external whenNotPaused {
        StakeInfo storage stakeInfo = stakes[msg.sender];
        require(stakeInfo.amount > 0, "No active stake");

        uint256 timeStaked = block.timestamp - stakeInfo.startTime;
        uint256 reward = (stakeInfo.amount / 1_000_000) *
            REWARD_RATE *
            (timeStaked / 1 days);
        require(reward > 0, "No rewards available");

        stakeInfo.claimedRewards += reward;
        bossToken.transfer(msg.sender, reward);

        emit RewardsClaimed(msg.sender, reward);
    }

    function withdraw() external whenNotPaused {
        StakeInfo storage stakeInfo = stakes[msg.sender];
        require(block.timestamp >= stakeInfo.unlockTime, "Unlock period not met");
        require(stakeInfo.amount > 0, "No funds to withdraw");

        uint256 amount = stakeInfo.amount;
        stakeInfo.amount = 0;

        bossToken.transfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function updateBossToken(address _bossToken) external onlyOwner {
        bossToken = IERC20(_bossToken);
    }

    function updateFees(
        uint256 _stakingFee,
        uint256 _unlockFee
    ) external onlyOwner {
        STAKING_FEE = _stakingFee;
        UNLOCK_FEE = _unlockFee;
        emit FeesUpdated(_stakingFee, _unlockFee, block.timestamp);
    }

    function updateRewardRate(uint256 _rewardRate) external onlyOwner {
        REWARD_RATE = _rewardRate;
        emit RewardRateUpdated(_rewardRate, block.timestamp);
    }

    function updateUnlockPeriod(uint256 _unlockPeriod) external onlyOwner {
        UNLOCK_PERIOD = _unlockPeriod;
        emit UnlockPeriodUpdated(_unlockPeriod, block.timestamp);
    }

    function updateFeeWallet(address _feeWallet) external onlyOwner {
        fee_wallet = _feeWallet;
        emit FeeWalletUpdated(_feeWallet, block.timestamp);
    }
}
