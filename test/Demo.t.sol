// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {Merkle} from "@murky/Merkle.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleWhitelistVotingStrategy {
    error InvalidProof();
    error InvalidMember();

    struct Member {
        address addr;
        uint96 vp;
    }

    function getVotingPower(uint32, /* blockNumber */ address voter, bytes calldata params, bytes calldata userParams)
        external
        pure
        returns (uint256 votingPower)
    {
        bytes32 root = abi.decode(params, (bytes32));
        (bytes32[] memory proof, Member memory member) = abi.decode(userParams, (bytes32[], Member));

        if (member.addr != voter) revert InvalidMember();
        if (MerkleProof.verify(proof, root, keccak256(abi.encode(member))) != true) revert InvalidProof();

        return member.vp;
    }
}

contract DemoTest is Test {
    error InvalidProof();
    error InvalidMember();

    MerkleWhitelistVotingStrategy public merkleWhitelistVotingStrategy;
    Merkle public merkleLib;

    function setUp() public {
        merkleWhitelistVotingStrategy = new MerkleWhitelistVotingStrategy();
        merkleLib = new Merkle();
    }

    function testDemo() public {
        MerkleWhitelistVotingStrategy.Member[] memory members = new MerkleWhitelistVotingStrategy.Member[](4);
        members[0] = MerkleWhitelistVotingStrategy.Member(address(3), 33);
        members[1] = MerkleWhitelistVotingStrategy.Member(address(1), 11);
        members[2] = MerkleWhitelistVotingStrategy.Member(address(5), 55);
        members[3] = MerkleWhitelistVotingStrategy.Member(address(5), 77);

        bytes32[] memory leaves = new bytes32[](4);
        leaves[0] = keccak256(abi.encode(members[0]));
        leaves[1] = keccak256(abi.encode(members[1]));
        leaves[2] = keccak256(abi.encode(members[2]));
        leaves[3] = keccak256(abi.encode(members[3]));

        bytes32 root = merkleLib.getRoot(leaves);

        // bytes32[] memory proof = merkleLib.getProof(leaves, 2);

        // Proof is for a different member than the voter address
        vm.expectRevert(InvalidMember.selector);
        merkleWhitelistVotingStrategy.getVotingPower(
            0, members[1].addr, abi.encode(root), abi.encode(merkleLib.getProof(leaves, 2), members[2])
        );
    }
}
