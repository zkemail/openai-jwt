// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {EmailProof, JwtVerifier} from "../../src/utils/JwtVerifier.sol";
import {JwtGroth16Verifier} from "../../src/utils/JwtGroth16Verifier.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {HexUtils} from "../../src/utils/HexUtils.sol";

contract JwtVerifierTest_verifyEmailProof is Test {
    using Strings for *;
    using HexUtils for bytes32;

    JwtVerifier verifier;

    constructor() {}

    function setUp() public {
        JwtVerifier verifierImpl = new JwtVerifier();
        JwtGroth16Verifier groth16Verifier = new JwtGroth16Verifier();
        ERC1967Proxy verifierProxy = new ERC1967Proxy(
            address(verifierImpl),
            abi.encodeCall(
                verifierImpl.initialize,
                (msg.sender, address(groth16Verifier))
            )
        );
        verifier = JwtVerifier(address(verifierProxy));
    }

    function test_verifyEmailProof() public {
        bytes32 accountCode = 0x1162ebff40918afe5305e68396f0283eb675901d0387f97d21928d423aaa0b54;

        // Verify the jwt proof
        string[] memory inputGenerationInput = new string[](2);
        inputGenerationInput[0] = string.concat(
            vm.projectRoot(),
            "/test/bin/generate.sh"
        );
        inputGenerationInput[1] = uint256(accountCode).toHexString(32);
        vm.ffi(inputGenerationInput);

        string memory publicInputFile = vm.readFile(
            string.concat(
                vm.projectRoot(),
                "/test/build_integration/public.json"
            )
        );
        string[] memory pubSignals = abi.decode(
            vm.parseJson(publicInputFile),
            (string[])
        );

        // kid -> pubSignals[0]
        bytes32 kid = bytes32(vm.parseUint(pubSignals[0]));
        string memory kidString = kid.bytes32ToHexString();
        // iss -> pubSignals[1] - pubSignals[2]
        string memory iss = "random.website.com";
        // publicKeyHash -> pubSignals[3]
        bytes32 publicKeyHash = bytes32(vm.parseUint(pubSignals[3]));
        // nullifier -> pubSignals[4]
        bytes32 jwtNullifier = bytes32(vm.parseUint(pubSignals[4]));
        // timestamp -> pubSignals[5]
        uint timeStamp = vm.parseUint(pubSignals[5]);
        // maskedCommand -> pubSignals[6] - pubSignals[25]
        string memory maskedCommand = "Send 0.1 ETH to alice@gmail.com";
        // accountSalt -> pubSignals[26]
        bytes32 accountSalt = bytes32(vm.parseUint(pubSignals[26]));
        // azp -> pubSignals[27] - pubSignals[29]
        string memory azp = "demo-client-id";
        // isCodeExist -> pubSignals[30]
        bool isCodeExist = vm.parseUint(pubSignals[30]) == 1;

        EmailProof memory emailProof;

        emailProof.domainName = string(
            abi.encodePacked(kidString, "|", iss, "|", azp)
        );
        emailProof.publicKeyHash = publicKeyHash;
        emailProof.timestamp = timeStamp;
        emailProof.maskedCommand = maskedCommand;
        emailProof.emailNullifier = jwtNullifier;
        emailProof.accountSalt = accountSalt;
        emailProof.isCodeExist = isCodeExist;
        emailProof.proof = proofToBytes(
            string.concat(
                vm.projectRoot(),
                "/test/build_integration/proof.json"
            )
        );

        require(verifier.verifyEmailProof(emailProof) == true, "verify failed");
    }

    function proofToBytes(
        string memory proofPath
    ) internal view returns (bytes memory) {
        string memory proofFile = vm.readFile(proofPath);
        string[] memory pi_a = abi.decode(
            vm.parseJson(proofFile, ".pi_a"),
            (string[])
        );
        uint256[2] memory pA = [vm.parseUint(pi_a[0]), vm.parseUint(pi_a[1])];
        string[][] memory pi_b = abi.decode(
            vm.parseJson(proofFile, ".pi_b"),
            (string[][])
        );
        uint256[2][2] memory pB = [
            [vm.parseUint(pi_b[0][1]), vm.parseUint(pi_b[0][0])],
            [vm.parseUint(pi_b[1][1]), vm.parseUint(pi_b[1][0])]
        ];
        string[] memory pi_c = abi.decode(
            vm.parseJson(proofFile, ".pi_c"),
            (string[])
        );
        uint256[2] memory pC = [vm.parseUint(pi_c[0]), vm.parseUint(pi_c[1])];
        bytes memory proof = abi.encode(pA, pB, pC);
        return proof;
    }
}
