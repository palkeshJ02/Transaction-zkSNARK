const { buildPoseidon } = require("circomlibjs");
const fs = require("fs");

async function generateInputs() {
    const poseidon = await buildPoseidon();

    // Define private inputs
    const oldBalanceAlice = 100;
    const oldBalanceBob = 50;
    const transferAmount = 20;

    const newBalanceAlice = oldBalanceAlice - transferAmount; // 80
    const newBalanceBob = oldBalanceBob + transferAmount;     // 70

    // Calculate public hashes using Poseidon
    const pubHashOld = poseidon.F.toString(poseidon([oldBalanceAlice, oldBalanceBob]));
    const pubHashNew = poseidon.F.toString(poseidon([newBalanceAlice, newBalanceBob]));

    // Construct the input object
    const inputs = {
        pubHashOld: pubHashOld,
        pubHashNew: pubHashNew,
        oldBalanceAlice: oldBalanceAlice,
        oldBalanceBob: oldBalanceBob,
        newBalanceAlice: newBalanceAlice,
        newBalanceBob: newBalanceBob,
        transferAmount: transferAmount
    };

    // Write to input.json
    fs.writeFileSync("input.json", JSON.stringify(inputs, null, 2));
    console.log("input.json successfully generated with valid Poseidon hashes.");
}

generateInputs();