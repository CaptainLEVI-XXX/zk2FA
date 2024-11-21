pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/poseidon.circom";
include "../../node_modules/circomlib/circuits/mux1.circom";

// Optimized hash leaves template
template HashLeaves() {
    signal input leftLeaf;
    signal input rightLeaf;
    
    signal output out;
    
    // Use Poseidon hash with direct input mapping
    component h = Poseidon(2);
    h.inputs[0] <== leftLeaf;
    h.inputs[1] <== rightLeaf;
    
    out <== h.out;
}

// Slightly optimized Merkle Tree Inclusion Verification
template MerkleTreeInclusionVerification(n) {
    // Input signals with clear naming
    signal input time;   // current timestamp
    signal input otp;    // one time passwords from the user
    signal input pathElements[n];  // this can be get via browser or IPFS/ Decentralized storage
    signal input pathIndex[n];
    
    // Output root signal
    signal output root;
    
    // Initial leaf computation
    signal leaf;
    component hl = HashLeaves();
    hl.leftLeaf <== time;
    hl.rightLeaf <== otp;
    
    leaf <== hl.out;
    
    // Precompute level hashes
    signal levelHashes[n+1];
    levelHashes[0] <== leaf;
    
    // Optimization: Declare components outside loop
    component h[n];
    component mux[n];
    
    // Merkle path verification loop
    for(var i = 0; i < n; i++) {
        // Strict binary path index constraint
        // Ensure path index is either 0 or 1
        pathIndex[i] * (1 - pathIndex[i]) === 0;    // check for binary
        
        // Initialize hash and multiplexer components
        h[i] = HashLeaves();
        mux[i] = MultiMux1(2);
        
        // Multiplexer configuration
        mux[i].c[0][0] <== levelHashes[i];
        mux[i].c[0][1] <== pathElements[i];
        mux[i].c[1][0] <== pathElements[i];
        mux[i].c[1][1] <== levelHashes[i];
        mux[i].s <== pathIndex[i];
        
        // Hash computation for next level
        h[i].leftLeaf <== mux[i].out[0];
        h[i].rightLeaf <== mux[i].out[1];
        
        // Update level hashes
        levelHashes[i+1] <== h[i].out;
    }
    
    // Final root computation
    root <== levelHashes[n];
}

// Main component with public time input
component main { public [time] } = MerkleTreeInclusionVerification(7);