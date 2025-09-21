import "FlowTransactionScheduler" 
import "FlowToken"
import "FungibleToken"

access(all) contract PinPin {

    /// Handler resource that implements the Scheduled Transaction interface
    access(all) resource Handler: FlowTransactionScheduler.TransactionHandler {

        access(FlowTransactionScheduler.Execute) fun executeTransaction(id: UInt64, data: AnyStruct?) {
            let storage = self.owner!.storage
            =
            
        }
    }

    init() {

    }
}