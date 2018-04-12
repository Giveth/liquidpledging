
/* global assert */

module.exports = async function(promise) {
    let web3_error_thrown = false;
    try {
        const tx = await promise;
        if (tx.receipt.status == '0x00') {
            web3_error_thrown = true;
        }
    } catch (error) {
        if (error.message.includes("invalid opcode") || error.message.includes('revert')) web3_error_thrown = true;
    }
    assert.ok(web3_error_thrown, "Transaction should fail");
};
