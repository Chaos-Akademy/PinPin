import "FlowTransactionScheduler" 
import "FlowToken"
import "FungibleToken"

access(all) contract PinPin {

    /// Handler resource that implements the Scheduled Transaction interface
    access(all) resource Handler: FlowTransactionScheduler.TransactionHandler {

        access(self) var vaultCap: Capability<auth(FungibleToken.Withdraw) &FlowToken>

        access(FlowTransactionScheduler.Execute) fun executeTransaction(id: UInt64, data: AnyStruct?) {
            // let storage = self.owner!.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowToken)
            // Get PinPin's Flow vault ref
            let pinPinVault = getAccount(PinPin.account.address).capabilities.borrow<&FlowToken.Vault>(/public/flowTokenReceiver)!
            // Get a reference to the vaultCap
            let ref = self.vaultCap.borrow()!
            // Deposit 0.1 Flow on the PinPin account
            pinPinVault.deposit(from: <- ref.withdraw(amount: 0.1))
            log("Account /self.owner!.address has made a deposit for a subscription")

            // Determine delay for the next transaction (default 3 seconds if none provided)
            var delay: UFix64 = 5.0
            if data != nil {
                let t = data!.getType()
                if t.isSubtype(of: Type<UFix64>()) {
                    delay = data as! UFix64
                }
            }

            let future = getCurrentBlock().timestamp + delay
            let priority = FlowTransactionScheduler.Priority.Medium
            let executionEffort: UInt64 = 1000

            let estimate = FlowTransactionScheduler.estimate(
                data: data,
                timestamp: future,
                priority: priority,
                executionEffort: executionEffort
            )       

            assert(
                estimate.timestamp != nil || priority == FlowTransactionScheduler.Priority.Low,
                message: estimate.error ?? "estimation failed"
            )   

            // Ensure a handler resource exists in the contract account storage
            if PinPin.account.storage.borrow<&AnyResource>(from: /storage/PinPin) == nil {
                let handler <- PinPin.createHandler(cap: self.vaultCap) 
                PinPin.account.storage.save(<-handler, to: /storage/PinPin)
            }  
        }

        init(_ cap: Capability<auth(FungibleToken.Withdraw) &FlowToken>) {
            self.vaultCap = cap
        }
    }

    /// Factory for the handler resource
    access(all) fun createHandler(cap: Capability<auth(FungibleToken.Withdraw) &FlowToken>): @Handler {
        return <- create Handler(cap)
    }

    init() {
        // Deposit a Cap to the vault that's going to pay for the transactions

    }
}