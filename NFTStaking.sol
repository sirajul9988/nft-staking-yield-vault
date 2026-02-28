// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTStaking is Ownable, ReentrancyGuard, IERC721Receiver {
    IERC721 public immutable nftCollection;
    IERC20 public immutable rewardToken;

    uint256 public rewardRatePerHour = 10 * 10**18; // 10 tokens per hour per NFT

    struct Stake {
        address owner;
        uint256 tokenId;
        uint256 timestamp;
    }

    mapping(uint256 => Stake) public vault;
    mapping(address => uint256) public userStakedBalance;

    event NFTStaked(address owner, uint256 tokenId, uint256 value);
    event NFTUnstaked(address owner, uint256 tokenId, uint256 value);
    event Claimed(address owner, uint256 reward);

    constructor(address _nftCollection, address _rewardToken) Ownable(msg.sender) {
        nftCollection = IERC721(_nftCollection);
        rewardToken = IERC20(_rewardToken);
    }

    function stake(uint256[] calldata tokenIds) external nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(nftCollection.ownerOf(tokenId) == msg.sender, "Not owner");

            nftCollection.safeTransferFrom(msg.sender, address(this), tokenId);

            vault[tokenId] = Stake({
                owner: msg.sender,
                tokenId: tokenId,
                timestamp: block.timestamp
            });
            
            userStakedBalance[msg.sender]++;
            emit NFTStaked(msg.sender, tokenId, block.timestamp);
        }
    }

    function unstake(uint256[] calldata tokenIds) external nonReentrant {
        uint256 reward = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            Stake memory stakedItem = vault[tokenId];
            require(stakedItem.owner == msg.sender, "Not the staker");

            reward += _calculateReward(stakedItem);

            delete vault[tokenId];
            userStakedBalance[msg.sender]--;
            nftCollection.safeTransferFrom(address(this), msg.sender, tokenId);

            emit NFTUnstaked(msg.sender, tokenId, block.timestamp);
        }

        if (reward > 0) {
            rewardToken.transfer(msg.sender, reward);
        }
    }

    function claim(uint256[] calldata tokenIds) external nonReentrant {
        uint256 reward = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            Stake storage stakedItem = vault[tokenId];
            require(stakedItem.owner == msg.sender, "Not the staker");

            reward += _calculateReward(stakedItem);
            stakedItem.timestamp = block.timestamp; // Reset timer
        }

        if (reward > 0) {
            rewardToken.transfer(msg.sender, reward);
            emit Claimed(msg.sender, reward);
        }
    }

    function _calculateReward(Stake memory _stake) internal view returns (uint256) {
        return ((block.timestamp - _stake.timestamp) * rewardRatePerHour) / 3600;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
