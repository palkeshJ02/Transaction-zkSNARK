#!/bin/bash


set -e 

echo "=========================================="
echo " 1. Initializing Project & Installing Dependencies"
echo "=========================================="
if [ ! -f "package.json" ]; then
    npm init -y > /dev/null 2>&1
fi
npm install circomlib circomlibjs snarkjs > /dev/null 2>&1 || { echo "Failed at Step 1: Dependency installation."; exit 1; }

echo "=========================================="
echo " 2. Generating Valid Inputs"
echo "=========================================="
if [ ! -f "generate_inputs.js" ]; then
    echo "Error: generate_inputs.js not found!"
    exit 1
fi
node generate_inputs.js > /dev/null 2>&1 || { echo "Failed at Step 2: Input generation."; exit 1; }

echo "=========================================="
echo " 3. Compiling the Circuit"
echo "=========================================="
circom transaction.circom --r1cs --wasm --sym > /dev/null 2>&1 || { echo "Failed at Step 3: Circuit compilation."; exit 1; }

echo "=========================================="
echo " 4. Generating the Witness"
echo "=========================================="
if [ ! -f "input.json" ]; then
    echo "Error: input.json was not generated correctly!"
    exit 1
fi

node transaction_js/generate_witness.js transaction_js/transaction.wasm input.json witness.wtns > /dev/null 2>&1 || { 
    echo "Failed at Step 4: Witness generation rejected!"
    echo "(The transaction constraints were violated by the inputs)."
    exit 1 
}

echo "=========================================="
echo " 5. Trusted Setup (Powers of Tau & Phase 2)"
echo "=========================================="
snarkjs powersoftau new bn128 12 pot12_0000.ptau > /dev/null 2>&1 || { echo "Failed at Step 5: Trusted Setup (new)."; exit 1; }
echo "random entropy" | snarkjs powersoftau contribute pot12_0000.ptau pot12_0001.ptau --name="First" > /dev/null 2>&1 || { echo "Failed at Step 5: Trusted Setup (contribute 1)."; exit 1; }
snarkjs powersoftau prepare phase2 pot12_0001.ptau pot12_final.ptau > /dev/null 2>&1 || { echo "Failed at Step 5: Trusted Setup (prepare phase2)."; exit 1; }

snarkjs groth16 setup transaction.r1cs pot12_final.ptau transaction_0000.zkey > /dev/null 2>&1 || { echo "Failed at Step 5: Trusted Setup (setup)."; exit 1; }
echo "more entropy" | snarkjs zkey contribute transaction_0000.zkey transaction_final.zkey --name="Second" > /dev/null 2>&1 || { echo "Failed at Step 5: Trusted Setup (zkey contribute)."; exit 1; }
snarkjs zkey export verificationkey transaction_final.zkey verification_key.json > /dev/null 2>&1 || { echo "Failed at Step 5: Trusted Setup (export key)."; exit 1; }

echo "=========================================="
echo " 6. Generating the SNARK Proof"
echo "=========================================="
snarkjs groth16 prove transaction_final.zkey witness.wtns proof.json public.json > /dev/null 2>&1 || { echo "Failed at Step 6: Proof generation."; exit 1; }

echo "=========================================="
echo " 7. Verifying the Proof"
echo "=========================================="

if snarkjs groth16 verify verification_key.json public.json proof.json > /dev/null 2>&1; then
    echo "SUCCESS! Proof verified mathematically."
else
    echo "FAILURE! The proof is invalid."
    exit 1
fi