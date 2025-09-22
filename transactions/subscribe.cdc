import "FlowTransactionScheduler"
import "FungibleToken"
import "FlowToken"
import "PinPin"

transaction() {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Get Cap
        let cap: Capability<auth(FungibleToken.Withdraw) &FlowToken.Vault> = signer.capabilities.storage.issue<auth(FungibleToken.Withdraw) &FlowToken.Vault>(/storage/flowTokenVault)
        // Save a handler resource to storage if not already present
        if signer.storage.borrow<&AnyResource>(from: /storage/PinPin) == nil {
            let handler <- PinPin.createHandler(cap: cap)
            signer.storage.save(<-handler, to: /storage/PinPin)
        }

        // Validation/example that we can create an issue a handler capability with correct entitlement for FlowTransactionScheduler
        let _ = signer.capabilities.storage
            .issue<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>(/storage/PinPin)
    }
} 