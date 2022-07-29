// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {treasureHunt} from '../src/treasureHunt.sol';

contract treasureHuntTest is Test {
    
    treasureHunt nft;
    
    function setUp() public {
        nft = new treasureHunt();
    }

    function testMint() public {
        vm.deal(address(0xBEEF), 1 ether);
        vm.startPrank(address(0xBEEF));
        
        nft.mint{value:0.01 ether}();

        assertEq(nft.balanceOf(address(0xBEEF)),1);
    }

    function testAddChallenge() public {

        bytes3[] memory plte = new bytes3[](1);
        plte[0] = hex'000000';

        bytes memory pixs = hex'000000000000000000000000000000';

        treasureHunt.CHALLENGE memory newChallenge = treasureHunt.CHALLENGE(
            "test challenge",
            msg.sender,
            plte,
            pixs,
            false,
            0
        );

        nft.addChallenge(newChallenge);

        assertEq(nft.challengeCount(),1);

    }

    function testSign() public {

        /*
        keccak256(
                    abi.encodePacked(
                        hex'1901',
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "PermitClaim(address manager,uint256 tokenId,uint256 challengeId,uint256 nonce,uint256 deadline)"
                                ),
                                manager,
                                tokenId,
                                challengeId,
                                challenges[challengeId].nonce++,
                                deadline
                            )
                        )
                    )
                ),
        */

        address mgr = vm.addr(69);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(69, keccak256("test sign"));

        address signer = ecrecover(keccak256("test sign"), v, r, s);

        assertEq(mgr, signer);

    }

    function testPermitClaim() public {

        //setting up
        address mgr = vm.addr(69);
        address claimer = vm.addr(420);

        vm.deal(mgr, 1 ether);
        vm.deal(claimer, 1 ether);

        uint256 _deadline = block.timestamp + 1000;

        //mint NFT to claimer
        vm.startPrank(claimer);
            nft.mint{value:0.01 ether}();
            assertEq(nft.balanceOf(claimer),1);
        vm.stopPrank();

        
        vm.startPrank(mgr);
            //setup challenge 
            bytes3[] memory plte = new bytes3[](1);
            plte[0] = hex'000000';

            bytes memory pixs = hex'000000000000000000000000000000';

            treasureHunt.CHALLENGE memory newChallenge = treasureHunt.CHALLENGE(
                "test challenge",
                mgr,
                plte,
                pixs,
                false,
                0
            );

            nft.addChallenge{value: 0.1 ether}(newChallenge);
            assertEq(nft.challengeCount(),1);


            //sign permission
            bytes32 permitHash =  keccak256(
                abi.encodePacked(
                    hex'1901',
                    nft.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "PermitClaim(address manager,uint256 tokenId,uint256 challengeId,uint256 nonce,uint256 deadline)"
                            ),
                            mgr,
                            0,
                            0,
                            0, //might need to iterate this
                            _deadline
                        )
                    )
                )
            );

            (uint8 v, bytes32 r, bytes32 s) = vm.sign(69, permitHash);

        vm.stopPrank();

        //claim challenge
        vm.startPrank(claimer);
            nft.permitClaim(mgr, 0, 0, _deadline, v,r,s);

            assertTrue(nft.checkBadgeStatus(0, 0));

        vm.stopPrank();

        readBadgeStatus(nft);        

    }

    function readBadgeStatus(treasureHunt _nft) public logs_gas {
        assertTrue(_nft.checkBadgeStatus(0, 0));  
    }

    
}
