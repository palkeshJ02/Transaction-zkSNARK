pragma circom 2.0.0;

// Import standard libraries for hashing and comparing numbers
include "node_modules/circomlib/circuits/poseidon.circom";
include "node_modules/circomlib/circuits/comparators.circom";

template Transaction() {
    // --------------------------------------------------
    // Public Inputs
    // --------------------------------------------------
    signal input pubHashOld; // Hash of the old balances 
    signal input pubHashNew; // Hash of the new balances 

    // --------------------------------------------------
    // Private Inputs
    // --------------------------------------------------
    signal input oldBalanceAlice; 
    signal input oldBalanceBob;   
    signal input newBalanceAlice; 
    signal input newBalanceBob;   
    signal input transferAmount; 

    // --------------------------------------------------
    // Constraint 1: Verify the old balances hash
    // --------------------------------------------------
    component hashOld = Poseidon(2);
    hashOld.inputs[0] <== oldBalanceAlice;
    hashOld.inputs[1] <== oldBalanceBob;
    
    // Enforce that the computed hash matches the public hash
    pubHashOld === hashOld.out;

    // --------------------------------------------------
    // Constraint 2: Verify the new balances hash
    // --------------------------------------------------
    component hashNew = Poseidon(2);
    hashNew.inputs[0] <== newBalanceAlice;
    hashNew.inputs[1] <== newBalanceBob;
    
    // Enforce that the computed hash matches the public hash
    pubHashNew === hashNew.out;

    // --------------------------------------------------
    // Constraint 3: Prevent Overspending (Underflow Check)
    // --------------------------------------------------
    // We restrict balances to 64 bits to safely check greater/less than.
    // This ensures oldBalanceAlice >= transferAmount.
    component checkFunds = GreaterEqThan(64);
    checkFunds.in[0] <== oldBalanceAlice;
    checkFunds.in[1] <== transferAmount;
    
    // The output of GreaterEqThan is 1 if true, 0 if false.
    checkFunds.out === 1;

    // --------------------------------------------------
    // Constraint 4: Verify Transaction Consistency
    // --------------------------------------------------
    // Prove that the math adds up correctly.
    newBalanceAlice === oldBalanceAlice - transferAmount;
    newBalanceBob === oldBalanceBob + transferAmount;
}

// Instantiate the main component and define which inputs are public.

component main {public [pubHashOld, pubHashNew]} = Transaction();

