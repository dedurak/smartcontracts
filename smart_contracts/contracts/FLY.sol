// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;


interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract FLY is IERC20 {

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  mapping (address => Payments[]) paymentsDone;

  address public contractOwner;

  uint256 private _totalSupply;

  string public name;
  string public symbol;

  struct Payments {
    string amount;
    address _sender;
    address _recipient;
    string timestamp;
  }

  constructor() public {
    contractOwner = msg.sender;
    name = "FlyCoin";
    symbol = "FLY";
    _totalSupply = 0;
  } 

  /** 
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view override returns(uint256) {
    return _totalSupply;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) public view override returns (uint256) {
    return _balances[owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address owner,
    address spender
   )
    public
    view
    override
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public override returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    _balances[msg.sender] = _balances[msg.sender]-value;
    _balances[to] = _balances[to]+value;


    emit Transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public override returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }


  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    override
    returns (bool)
  {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from]-value;
    _balances[to] = _balances[to]+value;
    _allowed[from][msg.sender] = _allowed[from][msg.sender]-value;
    emit Transfer(from, to, value);
    return true;
  }


  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender]+addedValue);
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }


  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender]-subtractedValue);
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }


  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param amount The amount that will be created.
   */
  function _mint(address account, uint256 amount) public {
    _totalSupply = _totalSupply+amount;
    _balances[account] = _balances[account]+amount;
    emit Transfer(address(0), account, amount);
  }


  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param amount The amount that will be burnt.
   */
  function _burn(address account, uint256 amount) public {
    require(amount <= _balances[account]);

    _totalSupply = _totalSupply-amount;
    _balances[account] = _balances[account]-amount;
    emit Transfer(account, address(0), amount);
  }


  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender's allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param amount The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 amount) internal {
    require(amount <= _allowed[account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender]-amount;
    _burn(account, amount);
  }


  // function handles the refund of the ticket price if flight is cancelled
  function paymentHandlerCancelled(address cust, uint price) public isOwner() {
    require(cust != address(0));
    transfer(cust, price);

    emit PaymentRefunded(msg.sender, cust, price);
  }


  // handle refund if delayed
  function paymentHandlerDelayed(address cust, uint dist) public isOwner(){

    require(cust != address(0));
    uint amount;

    if(dist < 1500) {
      amount = 250;
      transfer(cust, 250);
    }
    if(dist >= 1500 && dist <=3500) {
      amount = 400;
      transfer(cust, 400);
    }
    else {
      amount = 600;
      transfer(cust, 600);
    }

    emit DelayRefunded(msg.sender, cust, amount);
  }


  // insert new payments 
  function insertPayment(string memory _amount, address addr, string memory timestamp) public {
    Payments memory _bufToInsert = Payments(_amount, msg.sender, addr, timestamp);
    paymentsDone[msg.sender].push(_bufToInsert);
    paymentsDone[addr].push(_bufToInsert);

    emit NewPaymentInsert(_amount, msg.sender, addr, timestamp);
  }


  // search for payments and return max.10 ( amount[], _sender[], recipient[], timestamp[])
  function searchPayments(uint length) public view returns (string memory, address[] memory, address[] memory, string memory)
  {
    Payments[] memory bufPayments = paymentsDone[msg.sender];
    uint len = bufPayments.length;

    if(len>length) {
      len = length;
    }
    
    // return arrays
    string[] memory retAmount = new string[](len);
    address[] memory retSender = new address[](len);
    address[] memory retRecipient = new address[](len);
    string[] memory retTimestamp = new string[](len);

    // parse through all bufPayments and insert into return arrays
    for(uint ind = 0; ind < len; ind++) {
      if(bufPayments[ind]._sender == msg.sender) {
        retAmount[ind] = bufPayments[ind].amount;
        retSender[ind] = msg.sender;
        retRecipient[ind] = bufPayments[ind]._recipient;
        retTimestamp[ind] = bufPayments[ind].timestamp;
      } else if(bufPayments[ind]._recipient == msg.sender) {
        retAmount[ind] = bufPayments[ind].amount;
        retSender[ind] = bufPayments[ind]._sender;
        retRecipient[ind] = msg.sender;
        retTimestamp[ind] = bufPayments[ind].timestamp;
      }
    }

    string memory reAm = concatStrings(retAmount);
    string memory tiSt = concatStrings(retTimestamp);
    
    return (reAm, retSender, retRecipient, tiSt);
  }



  /**
  * @dev concat all cids with underline between each one
  */
  function concatStrings(string[] memory toConcat) private pure
  returns(string memory)
  {
    uint length = toConcat.length;
    uint strLength = 0;

    if(length == 1) { return(toConcat[0]); }
                
    else {
      string memory differ = "_";
      bytes memory bDiffer = bytes(differ);
      // get count of bytes
      for(uint ind = 0; ind < length; ind++) 
      {
        bytes memory buf = bytes(toConcat[ind]);
        strLength += buf.length;
        if(ind < (length-1)) 
        {
          strLength += bDiffer.length;
        }
      }

      string memory bufStr = new string(strLength);
      bytes memory concatBytes = bytes(bufStr);

      uint indK = 0;
      for(uint ind = 0; ind < toConcat.length; ind++)
      {
        bytes memory tt = bytes(toConcat[ind]);
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

  modifier isOwner() {
    require (msg.sender == contractOwner);
    _;
  }

  event PaymentRefunded(address from, address to, uint amount);
  event DelayRefunded(address from, address to, uint amount);
  event NewPaymentInsert(string amount, address from, address to, string timestamp);
}
