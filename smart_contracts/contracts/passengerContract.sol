// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7;

/**
*   @author Deniz Durak
 */


/**
*   @dev this is a try to abstract the PSS of airlines in real world
*   all functions of this contract are only called if the payments, inside 
*   FlightToken contract, are completed.
*   
*   in case of following refund to the customer, this contract reports to customer
*   the client automatically reports this to the FlightToken contract. This contract then
*   refunds if granted
*
 */

contract passengerContract {

    address owner; // owner is the airline
    mapping(address => FlightTicket[]) ticketBase; // one cust can book many tickets
    mapping(uint => FlightStatus) flightStatusMap;
    mapping(uint => PassengerStatus) passStatusMap;
    Flight[] flights;

    enum FlightStatus {
        PLANNED, CANCELLED, CHECKIN, BOARDING, DEP_ON_TIME, ARR_ON_TIME, DEP_DELAYED, ARR_DELAYED
    }

    enum PassengerStatus {
        BOOKED, CHECKEDIN, BOARDED, DEPARTED, ARRIVED, CANCELLED, OVERBOOKED
    }

    constructor() public {
        owner = msg.sender;

        flightStatusMap[0] = FlightStatus.PLANNED;
        flightStatusMap[1] = FlightStatus.CANCELLED;
        flightStatusMap[2] = FlightStatus.CHECKIN;
        flightStatusMap[3] = FlightStatus.BOARDING;
        flightStatusMap[4] = FlightStatus.DEP_ON_TIME;
        flightStatusMap[5] = FlightStatus.ARR_ON_TIME;
        flightStatusMap[6] = FlightStatus.DEP_DELAYED;
        flightStatusMap[7] = FlightStatus.ARR_DELAYED;

        passStatusMap[0] = PassengerStatus.BOOKED;
        passStatusMap[1] = PassengerStatus.CHECKEDIN;
        passStatusMap[2] = PassengerStatus.BOARDED;
        passStatusMap[3] = PassengerStatus.DEPARTED;
        passStatusMap[4] = PassengerStatus.ARRIVED;
        passStatusMap[5] = PassengerStatus.CANCELLED; // from airline or passenger
        passStatusMap[6] = PassengerStatus.OVERBOOKED; // if flight is overbooked - new ticket status
    }

    struct FlightTicket {
        string cid; // ipfs hash to json ticket data
        uint flightIndex; // points to a struct flight
        PassengerStatus pStatus;
        uint256 price; // price in wei
    }

    struct Flight {
        string flightNumber;
        uint month;
        uint day;  // day + month + flightNumber important for status change
        address[] passengerList;
        FlightStatus fStatus;
    }

    function createTicket
    (
        string memory cid, // pointer to ticket data
        string memory flightNumber,
        uint month,
        uint day,
        uint256 price
    ) 
    public
    returns (bool)
    {

        // check if flight exists

        for(uint ind = 0; ind<flights.length; ind++) {
            if(compareStrings(flights[ind].flightNumber, flightNumber) && flights[ind].month == month && flights[ind].day == day) {
                ticketBase[msg.sender].push(FlightTicket(cid, ind, passStatusMap[0], price));
                flights[ind].passengerList.push(msg.sender); 
                emit TicketIssued(msg.sender, flightNumber, month, day);
                return true; // ticket isssued
            }
        }
        
        address[] memory passengerList;
        
        flights.push(Flight(flightNumber, month, day, passengerList, flightStatusMap[0])); // create new flight
        flights[flights.length-1].passengerList.push(msg.sender); // push msg.sender into passengerList
        
        ticketBase[msg.sender].push(FlightTicket(cid, flights.length-1, passStatusMap[0], price)); // create ticket
        
        emit FlightCreated(flightNumber, month, day);
        emit TicketIssued(msg.sender, flightNumber, month, day);
        
        return true; // ticket issued
    }


    //changes the status of the flight
    function changeFlightStatus(
        string memory flightNumber, uint month, uint day, uint _status
        ) public isAirline() 
        returns (bool, uint)
    {
        for(uint ind =0; ind<flights.length; ind++) {
            if(compareStrings(flights[ind].flightNumber, flightNumber) && flights[ind].month == month && flights[ind].day == day) {
                flights[ind].fStatus = flightStatusMap[_status];
                if(_status == 1 || _status == 7) {
                    emit FlightStatusChanged(flightNumber, month, day, _status);
                    return (true, 1); // true - status change done; 1 - status cancelled or arr_delay --> check for refund
                }
                emit FlightStatusChanged(flightNumber, month, day, _status);
                return (true, 0);
            }
        }
        return (false, 0);
    }


    // get PassengerList - to do the refund
    function getPassengerList(string memory flightNumber, uint month, uint day) 
    public view returns(address[] memory) {
        Flight memory buf;

        for(uint i = 0; i<flights.length; i++) {
            if(compareStrings(flights[i].flightNumber, flightNumber) && flights[i].month == month && flights[i].day == day) {
                buf = flights[i];
                break;
            }
        }

        return buf.passengerList;
    }


    // get ticket cids to fetch details about in frontend
    function getTickets() public view returns (string memory) {
        return(concatStrings(ticketBase[msg.sender]));
    }


    // change passenger status
    function changePassengerStatus(
        uint _status, string memory flightNumber
    ) public returns (bool) 
    {
        FlightTicket[] memory tickets = ticketBase[msg.sender];
        if(tickets.length == 1) {
            tickets[0].pStatus = passStatusMap[_status];
            emit PassengerStatusChanged(msg.sender, flightNumber, flights[tickets[0].flightIndex].month, flights[tickets[0].flightIndex].day, _status);
            return true;
        } else {
            for(uint ind = 0; ind < tickets.length; ind++) {
                if(compareStrings(flights[tickets[ind].flightIndex].flightNumber, flightNumber)) {
                    tickets[ind].pStatus = passStatusMap[_status];
                    // check if passenger status is cancelled --> if so, check the business rules for refund
                    emit PassengerStatusChanged(msg.sender, flightNumber, flights[tickets[ind].flightIndex].month, flights[tickets[ind].flightIndex].day, _status);
                    return true;
                }
            }
        }
        return false;
    }


    /**
    * @dev concat all cids with underline between each one
    */
    function concatStrings(FlightTicket[] memory tickets) private pure
    returns(string memory)
    {
        uint length = tickets.length;
        uint strLength = 0;

        if(length == 1) { return(tickets[0].cid); }
            
        else {
            string memory differ = "_";
            bytes memory bDiffer = bytes(differ);
            // get count of bytes
            for(uint ind = 0; ind < length; ind++) 
            {
                bytes memory buf = bytes(tickets[ind].cid);
                strLength += buf.length;
                if(ind < (length-1)) 
                {
                    strLength += bDiffer.length;
                }
            }
                
            string memory bufStr = new string(strLength);
            bytes memory concatBytes = bytes(bufStr);

            uint indK = 0;
            for(uint ind = 0; ind < tickets.length; ind++)
            {
                bytes memory tt = bytes(tickets[ind].cid);
                for(uint indJ = 0; indJ<tt.length; indJ++) 
                {
                    concatBytes[indK++] = tt[indJ];
                }

                if(ind < (length-1)) 
                {
                    for(uint indDiffer = 0; indDiffer < bDiffer.length; indDiffer++)
                    {
                        concatBytes[indK++] = bDiffer[indDiffer];
                    }
                }
            }
                
            return(string(concatBytes));
        }
    }
        

    /**
    * @dev compares cmp1 & cmp2
    */

    function compareStrings
    (
        string memory cmp1,
        string memory cmp2
    )
    private
    pure
    returns(bool)
    {
        return (keccak256(abi.encodePacked((cmp1))) == keccak256(abi.encodePacked((cmp2))));
    }


    modifier isAirline() {
        require(msg.sender == owner);
        _;
    }

    event TicketIssued(address customer, string flightNumber, uint month, uint day);
    event FlightCreated(string flightNumber, uint month, uint day);
    event FlightStatusChanged(string flightNumber, uint month, uint day, uint status);
    event PassengerStatusChanged(address customer, string flightNumber, uint month, uint day, uint status);
}
