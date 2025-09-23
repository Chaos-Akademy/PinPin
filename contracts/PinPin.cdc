import "FlowTransactionScheduler" 
import "FlowToken"
import "FungibleToken"

access(all) contract PinPin {
    // -----------------------------------------------------------------------
    // PinPin contract-level fields.
    // These contain actual values that are stored in the smart contract.
    // -----------------------------------------------------------------------
    access(all) var subscriptionFee: UFix64
    // Events
    access(all) event ContractInitialized()
    access(all) event SubscriptionActivated(subscriber: Address)

    /// Handler resource that implements the Scheduled Transaction interface
    access(all) resource Handler: FlowTransactionScheduler.TransactionHandler {

        access(self) var vault: @FlowToken.Vault

        access(FlowTransactionScheduler.Execute) fun executeTransaction(id: UInt64, data: AnyStruct?) {
            // Get PinPin's Flow vault ref
            let pinPinVault = PinPin.account.capabilities.borrow<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
            // Get a reference to the vaultCap
            let ref <- self.vault.withdraw(amount: 0.1)
            // Deposit 0 Flow on the PinPin account
            pinPinVault.deposit(from: <- ref.withdraw(amount: 0.01)) 
            log("Account /self.owner!.address has made a deposit for a subscription")
            emit SubscriptionActivated(subscriber: self.owner!.address)
            // Determine delay for the next transaction (default 3 seconds if none provided)
            var delay: UFix64 = 60.0
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

            // Withdraw FLOW fees from this resource's ownner account vault
            let fees <- ref.withdraw(amount: estimate.flowFee ?? 0.0) as! @FlowToken.Vault   

            // Issue a capability to the handler stored in this contract account
            let handlerCap = PinPin.account.capabilities.storage
                .issue<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>(/storage/PinPin)

            let receipt <- FlowTransactionScheduler.schedule(
                handlerCap: handlerCap,
                data: data,
                timestamp: future,
                priority: priority,
                executionEffort: executionEffort,
                fees: <-fees
            )

            log("Loop transaction id: ".concat(receipt.id.toString()).concat(" at ").concat(receipt.timestamp.toString()))
            
            destroy receipt
        }

        init(_ vault: @FlowToken.Vault,_ consentedFee: UFix64,_ consentedCycles: UFix64) {
            pre {
                PinPin.subscriptionFee == consentedFee: "Consented fee must be equal to contract's current fee"
                vault.balance >= consentedCycles * consentedFee: "Vault's balance must be equal or greater than Fees x Cycles"
            }
            self.vault <- vault
        }
    }

    /// Factory for the handler resource
    access(all) fun createHandler(vault: @FlowToken.Vault, consentedFee: UFix64, consentedCycles: UFix64): @Handler {
        return <- create Handler(<- vault, consentedFee, consentedCycles)
    }

    init() {
        self.subscriptionFee = 0.1
        emit ContractInitialized()
    }
}