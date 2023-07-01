# zk-blind

post anonymous confessions about your work place / organization in zero-knowledge!

`yarn` to install all dependencies.

## generate inputs

to generate inputs into `____.json`, replace `signature`, `msg`, and `ethAddress` in `node-ts scripts/generate_input.ts`. currently, this file will only generate inputs for OpenAI JWTs and JWTs generated by our dummy JWT generator application(https://get-jwt.vercel.app/), but feel free to add more public keys to support JWTs from different sites.

on the last line of `scripts/gen_inputs.ts`, edit the json file name.
```
ts-node scripts/generate_input.ts
```

## circuits

These circuits check for (1) valid rsa signature, (2) that the message is a JWT, (3) ownership of a specific email domain, and (4) JWT expiration.

compile circuits in root project directory.
```
./shell_scripts/1_compile.sh
```

generate witness
```
./shell_scripts/2_gen_wtns.sh
```
make sure to edit the input json file name to the correct input file you generated in the generate inputs step.

phase 2 and getting full zkey + vkey
```
snarkjs groth16 setup ./build/jwt/jwt.r1cs ./circuits/powersOfTau28_hez_final_22.ptau ./build/jwt/jwt_single.zkey

snarkjs zkey contribute ./build/jwt/jwt_single.zkey ./build/jwt/jwt_single1.zkey --name="1st Contributor Name" -v

snarkjs zkey export verificationkey ./build/jwt/jwt_single1.zkey ./build/jwt/verification_key.json

```

generate proof
```
snarkjs groth16 prove ./build/jwt/jwt_single1.zkey ./build/jwt/witness.wtns ./build/jwt/proof.json ./build/jwt/public.json
```

verify proof offchain
```
snarkjs groth16 verify ./build/jwt/verification_key.json ./build/jwt/public.json ./build/jwt/proof.json
```

generate verifier.sol
```
snarkjs zkey export solidityverifier ./build/jwt/jwt_single1.zkey contracts/Verifier.sol
```

run local hardhat test
```
npx hardhat test ./test/blind.test.js
```

deploy blind and verifier contracts
```
npx hardhat run ./scripts/deploy.js --network goerli
```

## on-chain verification

in our code, we have examples of verifying an OpenAI JWT on-chain. however, `./contracts/Blind.sol` is not updated with the current state of the circuit, since our proof of concept app, Nozee, does not use on-chain verification.

however, if you are interested in deploying on-chain, `./scripts/deploy.js` allows you to do a hardhat deploy, and `./test/blind.test.js` are examples of how we tested and deployed our previously working Blind.sol contract.

run hardhat contract tests, first create a `secret.json` file that has a private key and goerli node provider endpoint.
```
yarn test
```
