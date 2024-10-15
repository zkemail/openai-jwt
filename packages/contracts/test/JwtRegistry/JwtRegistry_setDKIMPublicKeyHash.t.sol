// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@zk-email/contracts/DKIMRegistry.sol";
import {JwtRegistryTestBase} from "./JwtRegistryBase.t.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract JwtRegistryTest_setDKIMPublicKeyHash is JwtRegistryTestBase {
    constructor() {}

    function setUp() public override {
        super.setUp();
    }

    function testRevert_setDKIMPublicKeyHash_publicKeyHashIsAlreadySet()
        public
    {
        vm.startPrank(deployer);
        string memory domainName = "12345|https://example.com|client-id-12345";
        vm.expectRevert(bytes("publicKeyHash is already set"));
        jwtRegistry.setDKIMPublicKeyHash(domainName, publicKeyHash);
        vm.stopPrank();
    }

    function testRevert_setDKIMPublicKeyHash_publicKeyHashIsRevoked() public {
        vm.startPrank(deployer);
        string memory domainName = "12345|https://example.com|client-id-12345";
        jwtRegistry.revokeDKIMPublicKeyHash(domainName, publicKeyHash);
        vm.expectRevert(bytes("publicKeyHash is revoked"));
        jwtRegistry.setDKIMPublicKeyHash(domainName, publicKeyHash);
        vm.stopPrank();
    }

    function testRevert_setDKIMPublicKeyHash_OwnableUnauthorizedAccount()
        public
    {
        vm.startPrank(vm.addr(2));
        string memory domainName = "12345|https://example.com|client-id-12345";
        vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUpgradeable.OwnableUnauthorizedAccount.selector,
                vm.addr(2)
            )
        );
        jwtRegistry.setDKIMPublicKeyHash(domainName, publicKeyHash);
        vm.stopPrank();
    }

    function test_setDKIMPublicKeyHash() public {
        vm.startPrank(deployer);
        string memory domainName = "12345|https://example.xyz|client-id-12345";
        jwtRegistry.setDKIMPublicKeyHash(domainName, publicKeyHash);
        assertEq(jwtRegistry.whitelistedClients("client-id-12345"), true);
        vm.stopPrank();
    }
}
