// SPDX-License-Identifier: MIT

// Flappy Boss Game rewards Contract

// Allow specific players (top 5 on the leaderboard) to claim predefined amounts of $QUAI and $BOSS each week.

pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC20.sol";

contract FlappyDistributor is Ownable, Pausable {
    IERC20 public bossToken;

    uint256 public BOSS_REWARD_POOL;
    uint256 public QUAI_REWARD_POOL;
    uint256 public constant multiplier = 10 ** 18;

    address[] public claimers;

    mapping(address => bool) public eligibleClaimers;
    mapping(address => bool) public hasClaimedThisWeek;
    mapping(address => uint256) public claimableBOSS;
    mapping(address => uint256) public claimableQUAI;

    event RewardsClaimed(
        address indexed claimer,
        uint256 bossAmount,
        uint256 quaiAmount
    );
    event WeeklyClaimsReset();

    constructor(address _bossToken) Ownable(msg.sender) {
        bossToken = IERC20(_bossToken);
        BOSS_REWARD_POOL = 20000 * multiplier;
        QUAI_REWARD_POOL = 10 * multiplier;
    }

    function setEligibleClaimers(
        address[] calldata _claimers,
        uint256[] calldata bossAmounts,
        uint256[] calldata quaiAmounts
    ) external onlyOwner {
        require(
            _claimers.length == bossAmounts.length &&
                _claimers.length == quaiAmounts.length,
            "Mismatched input arrays"
        );

        delete claimers;

        for (uint256 i = 0; i < _claimers.length; i++) {
            eligibleClaimers[_claimers[i]] = true;
            claimableBOSS[_claimers[i]] = bossAmounts[i];
            claimableQUAI[_claimers[i]] = quaiAmounts[i];
            claimers.push(_claimers[i]);
        }
    }

    function claimRewards() external whenNotPaused {
        require(eligibleClaimers[msg.sender], "Not eligible for rewards");
        require(!hasClaimedThisWeek[msg.sender], "Already claimed this week");

        uint256 bossAmount = claimableBOSS[msg.sender];
        uint256 quaiAmount = claimableQUAI[msg.sender];

        require(bossAmount > 0 || quaiAmount > 0, "No rewards available");
        require(
            BOSS_REWARD_POOL >= bossAmount && QUAI_REWARD_POOL >= quaiAmount,
            "Pool is not enough"
        );

        hasClaimedThisWeek[msg.sender] = true;

        if (bossAmount > 0) {
            require(
                bossToken.transfer(msg.sender, bossAmount),
                "BOSS transfer failed"
            );
        }
        if (quaiAmount > 0) {
            require(
                address(this).balance >= quaiAmount,
                "Insufficient QUAI balance"
            );
            (bool sent, ) = msg.sender.call{value: quaiAmount}("");
            require(sent, "QUAI transfer failed");
        }

        emit RewardsClaimed(msg.sender, bossAmount, quaiAmount);
    }

    function resetWeeklyClaims() external onlyOwner {
        for (uint256 i = 0; i < claimers.length; i++) {
            hasClaimedThisWeek[claimers[i]] = false;
        }
        emit WeeklyClaimsReset();
    }

    function updateRewardPool(
        uint256 _BOSS_REWARD_POOL,
        uint256 _QUAI_REWARD_POOL
    ) external onlyOwner {
        BOSS_REWARD_POOL = _BOSS_REWARD_POOL * multiplier;
        QUAI_REWARD_POOL = _QUAI_REWARD_POOL * multiplier;
    }

    function updateRewardTokens(address _bossToken) external onlyOwner {
        bossToken = IERC20(_bossToken);
    }

    function pauseContract() external onlyOwner {
        _pause();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
    }
}
