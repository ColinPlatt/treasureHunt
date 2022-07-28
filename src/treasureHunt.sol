// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721}    from 'solmate/tokens/ERC721.sol';
import {Auth, Authority}       from 'solmate/auth/Auth.sol';

// add requiresAuth
contract treasureHunt is ERC721 {

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;



    struct CHALLENGE{
        string name;
        address manager;
        bytes3[] palette; // index of colors for the pixel image
        bytes pixels;  // pixels are tightly packed bits to the index colours
        bool revokeable; // challenges can be revokable, meaning that a manager can take away the badge from a user if they violate some rule related to the badge
        uint160 nonce; // nonce for EIP-712 logic
    }

    CHALLENGE[] challenges;

    //completedChallenges[id][challenges[]]
    mapping(uint256 => uint256[]) public completedChallenges;

    //challengeDisplayOrder[id][challengeId]
    mapping(uint256 => uint256[10]) public challengeDisplayOrder;

    //managers[address][approved_flag]
    mapping(address => bool) public managers;

    ////////////////////////////////////////////// EVENTS //////////////////////////////////////////
    event NEW_CHALLENGE(uint256 indexed challengeId, string name, bool revokeable);
    event CHALLENGE_UPDATED(uint256 indexed challengeId, string name, bool revokeable);
    event NEW_CLAIM(uint256 indexed tokenId, uint256 challengeId);
    event BADGE_REVOKED(uint256 indexed tokenId, uint256 challengeId);
    ////////////////////////////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////// CONSTRUCTOR /////////////////////////////////////////
        constructor(/*Authority _authority*/)
        ERC721("treasureHunt", "HUNT")
        /* Auth(msg.sender, _authority) */ 
    {
        managers[msg.sender] = true;
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////// USER FUNCTIONS ///////////////////////////////////////
    uint256 constant MINT_PRICE = 0.0 ether;
    uint256 private nextId;

    // There is no limit to the number of treasureHunts that can be minted, but there is a cost to mint, 
    // and they are blank upon initialization. So the value is created by the owner by completing challengers
    function mint() external payable {
        require(msg.value >= MINT_PRICE, "INSUFFICIENT MINT PAYMENT");
        _mint(msg.sender, nextId);
        nextId++;
    }

    function mint(uint256 amt) external payable {
        require(msg.value >= MINT_PRICE * amt, "INSUFFICIENT MINT PAYMENT");
        for(uint256 i = 0; i<amt;i++){
            _mint(msg.sender, nextId);
            nextId++;
        }
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////// CHALLENGE CLAIM FUNCTIONS /////////////////////////////////////

    // We allow two types of claim logic (set by the manager):
    // 1) a purely onchain claim (e.g. hold token X, make claim, log challenge completion)
    // 2) a 712 signature by the claim manager (e.g. user performs offchain challenge and is permitted to make claim and log challenge completion)  


    function permitClaim(
        address manager, 
        uint256 tokenId, 
        uint256 challengeId, 
        uint256 deadline,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) public {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");
        require(manager == challenges[challengeId].manager, "UNAUTHORIZED_MANAGER");
        require(msg.sender == ownerOf(tokenId), "NOT_OWNER");
        
        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow
        // and would be greater than the number of permissable addresses.
        unchecked {
            address recoveredAddress = ecrecover(
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
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == manager, "INVALID_SIGNER");

            completedChallenges[tokenId].push(challengeId);
        }
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////// VIEW FUNCTIONS ///////////////////////////////////////

    function tokenURI(uint256 id) public view override returns (string memory) {
        return 's';
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////// CHALLENGE MANAGEMENT FUNCTIONS ////////////////////////////////

    uint256 constant CHALLENGE_PRICE = 0.1 ether;

    // challenge managers can be "onboarded" by the contract owner, this gives them permission to create free challenges
    // add requiresAuth
    function addManager(address newManager) external {

    }

    // add requiresAuth
    function removeManager(address oldManager) external {
        
    }

    // add requiresAuth
    function addChallenge(CHALLENGE memory newChallenge) payable external {
        require(msg.value >= CHALLENGE_PRICE || managers[msg.sender], "INSUFFICIENT CHALLENGE LOG PAYMENT");

        uint256 challengeId = challenges.length;

        challenges.push(newChallenge);

        emit NEW_CHALLENGE(challengeId, newChallenge.name, newChallenge.revokeable);


    }

    // add requiresAuth
    function revokeBadge(uint256 tokenId, uint256 challengeId) external {


    }

    ////////////////////////////////////////////////////////////////////////////////////////////////

    ////////////////////////////// TREASURY MANAGEMENT FUNCTIONS ///////////////////////////////////

    // add requiresAuth
    function withdrawTresury() external {

    }

    ////////////////////////////////////////////////////////////////////////////////////////////////




}
