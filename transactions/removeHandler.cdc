import "FlowTransactionScheduler"
import "FungibleToken"
import "FlowToken"
import "PinPin"

transaction() {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Get Cap
        let cap <- signer.storage.load<@PinPin.Handler>(from: /storage/PinPin)!
        
        destroy cap

    }
}