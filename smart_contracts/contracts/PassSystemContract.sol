    // SPDX-License-Identifier: MIT
    pragma solidity >=0.6.7;
    pragma experimental ABIEncoderV2;

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

    contract PassSysContract {

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


        //changes the status of the flight -- TODO: check if any passengerstatus changes are necessary
        function changeFlightStatus
        (
            string memory flightNumber, uint month, uint day, uint _status
        ) 
        public isAirline() returns (bool, uint)
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


        // get flight status
        function getFlightStatus(
            string memory flightNumber, uint month, uint day
        ) public view returns(string memory) 
        {
            for(uint ind =0; ind<flights.length; ind++) {
                if(compareStrings(flights[ind].flightNumber, flightNumber) && flights[ind].month == month && flights[ind].day == day) {
                    FlightStatus status = flights[ind].fStatus;

                    for(uint j = 0; ; j++) {
                        if(flightStatusMap[j] == status) {
                            string memory s = uintToString(j);
                            return s;
                        }
                    }
                }
            }
        }

        function getPassengerStatus(string memory flightNumber, uint month, uint day) public view returns(string memory) 
        {
            uint len = ticketBase[msg.sender].length;
            PassengerStatus stat;

            for(uint i = 0; i<len; i++) {
                Flight memory fl = flights[ticketBase[msg.sender][i].flightIndex];
                if(compareStrings(flightNumber, fl.flightNumber) 
                    && month == fl.month 
                    && day == fl.day){
                    stat = ticketBase[msg.sender][i].pStatus;
                    break;
                }
            }
            for(uint j = 0; ; j++) {
                if(passStatusMap[j] == stat) {
                    string memory s = uintToString(j);
                    return s;
                }
            }
        }

        // get PassengerList - to do the refund
        function getPassengerList(string memory flightNumber, uint month, uint day) 
        public view isAirline() returns(address[] memory) {
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
            uint _status, string memory flightNumber, uint month, uint day
        ) public returns (bool) 
        {
            uint len = ticketBase[msg.sender].length;
            FlightTicket[] memory mFlights = ticketBase[msg.sender];

            for(uint i = 0; i<len; i++) {
                if(compareStrings(flights[mFlights[i].flightIndex].flightNumber, flightNumber) 
                    && flights[mFlights[i].flightIndex].month == month
                    && flights[mFlights[i].flightIndex].day == day)
                {
                    ticketBase[msg.sender][i].pStatus = passStatusMap[_status];
                    
                    if(_status == 5) {
                        emit TicketCancelled(msg.sender, ticketBase[msg.sender][i].price); // AirlineOracle listens to and sends back the money
                    }

                    emit PassengerStatusChanged(msg.sender, flights[ticketBase[msg.sender][i].flightIndex].flightNumber, 
                                                flights[ticketBase[msg.sender][i].flightIndex].month, flights[ticketBase[msg.sender][i].flightIndex].day, _status);
                    return true;
                }
            }
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

        function uintToString(uint v) internal pure returns (string memory str) {

            if(v == 0) {
                return "0";
            } else if (v == 1) {
                return "1";
            } else if (v == 2) {
                return "2";
            } else if (v == 3) {
                return "3";
            } else if (v == 4) {
                return "4";
            } else if (v == 5) {
                return "5";
            } else if (v == 6) {
                return "6";
            } else if (v == 7) {
                return "7";
            }
        }


        modifier isAirline() {
            require(msg.sender == owner);
            _;
        }

        event TicketIssued(address customer, string flightNumber, uint month, uint day);
        event TicketCancelled(address customer, uint price);
        event FlightCreated(string flightNumber, uint month, uint day);
        event FlightStatusChanged(string flightNumber, uint month, uint day, uint status);
        event PassengerStatusChanged(address customer, string flightNumber, uint month, uint day, uint status);
    }
