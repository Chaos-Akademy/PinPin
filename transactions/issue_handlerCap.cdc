// This transaction is a template for a transaction that
// could be used by anyone to send tokens to another account
// that has been set up to receive tokens.
//
// The withdraw amount and the account from getAccount
// would be the parameters to the transaction

import "FungibleToken"
import "FlowToken"

transaction() {

    prepare(signer: auth(IssueStorageCapabilityController) &Account) {

        let cap: Capability<auth(FungibleToken.Withdraw) &FlowToken> = signer.capabilities.storage.issue<auth(FungibleToken.Withdraw) &FlowToken>(/storage/flowTokenVault)

    }
}