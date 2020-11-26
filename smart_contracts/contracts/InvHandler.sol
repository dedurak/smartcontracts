    // SPDX-License-Identifier: MIT
    pragma solidity >=0.6.7;
    pragma experimental ABIEncoderV2;

     /**
    * @author Deniz Durak
    */
   
/**
*   this contracts only administrates the capacity for each flight. 
*   before a flight is bookable, the inventory has to be created
 */

    contract InvHandler {
        
        address public owner;
        Inv[] inv;

        // string points to date and this to the cid
        mapping(string => mapping(uint => mapping( uint => string))) invedFlights;


        constructor() public {
            owner = msg.sender;
        }

        /**
        * this is the struct for the inventory
         */
        struct Inv {
            string cid;
            string flightNumber;
            uint month;
            uint day;
            uint openSeats;
            uint bookedSeats;
        }


        // create new inventory
        function createInventory
        (
            string memory cid,
            string memory flightNumber,
            uint month,
            uint day,
            uint seats
        )
        public
        isAirline()
        {
            inv.push(Inv(cid, flightNumber, month, day, seats, 0));
            invedFlights[flightNumber][month][day] = cid;
            emit InventoryCreated(flightNumber, month, day);
        }


        // search for inventory and return count of seats available
        function searchInventory
        (
            string memory flightNumber,
            uint month,
            uint day
        )
        public
        view
        // (seats, array index)
        returns(uint, uint, string memory)
        {
            for(uint indArray = 0; indArray<inv.length; indArray++) {
                if(compareStrings(inv[indArray].flightNumber, flightNumber) && inv[indArray].month == month && inv[indArray].day == day) {
                    return (inv[indArray].openSeats, indArray, invedFlights[flightNumber][month][day]);
                }
            }
        }


        // only access for contract owner (the airline) - get all inventorized flights
        function searchFlights(uint month, uint day) public view isAirline() 
            returns(string memory) {

            string memory res = concatStrings(month, day);

            return (res);
        }


        // flight has been booked - seats minus 1
        function flightBooked
        (
            uint index
        )
        public
        returns (bool)
        {
            if(inv[index].openSeats > 0){
                inv[index].openSeats -= 1;
                inv[index].bookedSeats += 1;
                emit FlightBooked(inv[index].flightNumber, inv[index].month, inv[index].day);
                return true;
            }
            else return false;
        }

        function flightTicketCancelled (string memory flightNo, uint month, uint day) public 
        {
            for(uint ind = 0; ind<inv.length; ind++)
            {
                if(compareStrings(inv[ind].flightNumber, flightNo) && 
                    inv[ind].month == month &&  
                    inv[ind].day == day) 
                {
                    inv[ind].openSeats += 1;
                    inv[ind].bookedSeats -= 1;
                }
            }
        }


        /**
        * @dev concat all cids with underline between each one
         */
        function concatStrings
        (
            uint month, uint day
        )
        private
        view
        returns(string memory)
        {
            uint length = inv.length;
            uint strLength = 0;
            uint bufLength = 0;
            string memory differ = "_";
            bytes memory bDiffer = bytes(differ);

            for(uint ind = 0; ind<length; ind++) {
                
                if(inv[ind].month == month && inv[ind].day == day) {
                    bytes memory buf = bytes(inv[ind].cid);
                    strLength += buf.length;
                    if(ind < (length-1)) 
                    {
                        strLength += bDiffer.length;
                    }
                    ++bufLength;
                }
            }
            
            string memory bufStr = new string(strLength);
            bytes memory concatBytes = bytes(bufStr);

            uint indK = 0;
            for(uint ind = 0; ind < inv.length; ind++)
            {
                if(inv[ind].month == month && inv[ind].day == day) {
                    bytes memory tt = bytes(inv[ind].cid);
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
            }
                
            return(string(concatBytes));
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


        // modifier access only for owner
        modifier isAirline() {
            require (msg.sender == owner);
            _;
        }

        event FlightBooked(string flightNumber, uint month, uint day);
        event InventoryCreated(string flightNumber, uint month, uint day);
    }