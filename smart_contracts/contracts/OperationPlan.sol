    // SPDX-License-Identifier: MIT
    pragma solidity >=0.6.7;
    pragma experimental ABIEncoderV2;

    /**
    * @author Deniz Durak
    */
   
    contract OperationPlan {

        
        // storage values

        address public owner;
        Route[] private flights;
        mapping(uint => Status) private assignStatus;

        // 1st is the dep, 2nd arr, 3rd the cid
        mapping( string => mapping ( string => string[] ) ) private plan;

        /**
        * @param Flight represents route of Airline
        */

        struct Route {
            string from;
            string to;
            Status status;
        }

        enum Status {
            ACTIVE, CANCELLED
        }


        // constructor assigns the creator of the contract as owner
        // only owner can do mutations
        constructor() public{

            owner = msg.sender;
            
            assignStatus[0] = Status.CANCELLED;
            assignStatus[1] = Status.ACTIVE;
        }

        /**
        * @dev this function issues new flights and emits the FlightIssued event
        */

        function issueFlight(
            string memory _from, 
            string memory _to,
            uint _status,
            string memory cid
        )
            public
            validateStatus(_status)
        {
            flights.push(Route(_from, _to, assignStatus[_status]));
            plan[_from][_to].push(cid);
            
            emit newFlightIssued(_from, _to, _status);
        }

        /**
        * @dev search for flights inside flightPlan
        */

        function searchFlight(
            string memory _from,
            string memory _to
        )
        public
        view
        returns (string memory)
        {
            return(concatStrings(plan[_from][_to]));
        }


        /**
        * @dev concat all cids with underline between each one
         */
        function concatStrings
        (
            string[] memory cids
        )
        private
        pure
        returns(string memory)
        {
            uint length = cids.length;
            uint strLength = 0;

            if(length == 1) { return(cids[0]); }
            
            else {

                string memory differ = "_";
                bytes memory bDiffer = bytes(differ);
                // get count of bytes
                for(uint ind = 0; ind < length; ind++) 
                {
                    bytes memory buf = bytes(cids[ind]);
                    strLength += buf.length;
                    if(ind < (length-1)) 
                    {
                        strLength += bDiffer.length;
                    }
                }
                
                string memory bufStr = new string(strLength);
                bytes memory concatBytes = bytes(bufStr);

                uint indK = 0;
                for(uint ind = 0; ind < cids.length; ind++)
                {
                    bytes memory tt = bytes(cids[ind]);
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

        //  ** modifier ** 
        //
        // checks if the status is 0 or 1 
        //
        modifier validateStatus(uint _status) {
            require(_status < 2);
            _;
        }

        // events
        //
        event newFlightIssued(string _from, string _to, uint _status);
    }