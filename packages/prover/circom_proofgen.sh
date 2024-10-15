#!/bin/bash
set -e # Stop on error

if [ $# -ne 5 ]; then
    echo "Usage: $0 <circuitName> <nonce> <paramsDir> <buildDir> <isLocal>"
    exit 1
fi

circuitName=$1
nonce=$2
paramsDir=$3
buildDir=$4
isLocal=$5
SCRIPT_DIR=$(cd $(dirname $0); pwd)

input_path="${buildDir}/input_${circuitName}_${nonce}.json"
witness_path="${buildDir}/witness_${circuitName}_${nonce}.wtns"
proof_path="${buildDir}/rapidsnark_proof_${circuitName}_${nonce}.json"
public_path="${buildDir}/rapidsnark_public_${circuitName}_${nonce}.json"

cd "${SCRIPT_DIR}"
echo "entered zk email path: ${SCRIPT_DIR}"

${paramsDir}/${circuitName}_cpp/${circuitName} "${input_path}" "${witness_path}" | tee /dev/stderr
status_jswitgen=$?
echo "✓ Finished witness generation with cpp! ${status_jswitgen}"

if [ $isLocal = 1 ]; then
    # DEFAULT SNARKJS PROVER (SLOW)
    NODE_OPTIONS='--max-old-space-size=644000' snarkjs groth16 prove "${paramsDir}/${circuitName}.zkey" "${witness_path}" "${proof_path}" "${public_path}"
    status_prover=$?
    echo "✓ Finished slow proofgen! Status: ${status_prover}"
else
    # RAPIDSNARK PROVER GPU
    echo "ldd ${SCRIPT_DIR}/rapidsnark/package/bin/prover"
    ldd "${SCRIPT_DIR}/rapidsnark/package/bin/prover"
    status_lld=$?
    echo "✓ lld prover dependencies present! ${status_lld}"

    echo "${SCRIPT_DIR}/rapidsnark/package/bin/prover ${paramsDir}/${circuitName}.zkey ${witness_path} ${proof_path} ${public_path}"
    "${SCRIPT_DIR}/rapidsnark/package/bin/prover" "${paramsDir}/${circuitName}.zkey" "${witness_path}" "${proof_path}" "${public_path}"  | tee /dev/stderr
    status_prover=$?
    echo "✓ Finished rapid proofgen! Status: ${status_prover}"
fi

exit 0