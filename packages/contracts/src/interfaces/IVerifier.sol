// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

struct EmailProof {
    string domainName; // kid, iss, and azp are concatenated as a string with | as the delimiter
    bytes32 publicKeyHash; // Hash of the DKIM public key used in JWT/proof
    uint timestamp; // Timestamp of jWT
    string maskedCommand; // Masked command of jWT
    bytes32 emailNullifier; // Nullifier of the JWT to prevent its reuse.
    bytes32 accountSalt; // Create2 salt of the account
    bool isCodeExist; // Check if the account code is exist
    bytes proof; // ZK Proof of JWT
}

interface IVerifier {

    /**
     * @notice Verifies the provided JWT proof.
     * @param proof The JWT proof to be verified.
     * @return bool indicating whether the proof is valid.
     */    
    function verifyEmailProof(
        EmailProof memory proof
    ) external view returns (bool);

    /**
     * @notice Returns a constant value representing command bytes.
     * @return uint256 The constant value of command bytes.
     */
    function getCommandBytes() external pure returns (uint256);
}
