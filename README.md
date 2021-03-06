# smartcontracts

The smart contracts represent the typical process landscape of an airline booking system. 
The aim is to transform the business processes into a blockchain and further to advance the automation of processes, fulfilled by employees.


## FLY Token

The known booking processes have been transformed, in order to automatize all activities which are not as much consumer-friendly as the flight booking process itself, and are running with a blockchain in the backend. Thus, the process of refunding the payment for a booking, following on the cancellation of the operating airline, and the process of payimng the comparison payment, regulated by the european flight passenger regulations [EU 261/2004](https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=CELEX:32004R0261&from=EN), shall be fully automated.

FLY, an ERC20-Token with additional functions to complete  acts as the digital currency inside the new system. It's a ERC20-Token and has additional functions to enable the automization. The following key concepts are described in the following passage:
The struct Payments abstracts an executed payment and saves it inside the mapping structure paymentsDone. With this integration, developers have additionally the option to implement a gui, which displays all payments where the users address is involved.

`paymentHandlerCancelled()` --> the oracle runs this function if the airline cancels a flight or if the oracle receives a "TicketCancelled"
                                event from the PassengerSystem contract.

`paymentHandlerDelayed()` --> if the airline changes the state of the flight "ARR_DELAYED", it is necessary to insert the duration of the delay in minutes.
                              The oracle contains a method, which is checking if a comparison payment, regarding the passenger regulations article 7, 
                              needs to be done. If yes this is function is called with the information about the address of the customer and the distance
                              between the origins.

`insertPayment()` --> This function stores all fulfilled payments inside the mapping "paymentsDone".

`searchPayments()` --> in order to get an overview of payments where a client is involved, calling this fuction returns the data from "paymentsDone"
