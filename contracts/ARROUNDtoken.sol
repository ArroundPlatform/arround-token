pragma solidity 0.4.24;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

/**
 * @title ARROUND Tokens
 * @dev ARROUND Token, ERC20 implementation, contract based on Zeppelin contracts:
 * Ownable, BasicToken, StandardToken, ERC20Basic, Burnable
*/
contract ARROUNDtoken is Ownable {
    using SafeMath for uint256;
    
    enum State {Active, Finalized}
    State public state = State.Active;


    /**
     * @dev ERC20 descriptor variables
     */
    string public constant name = "ARROUND";
    string public constant symbol = "ARR";
    uint8 public decimals = 18;

    uint256 public constant startTime = 1542240000;
    
    
    uint256 public totalSupply_ = 3000 * 10 ** 24;

    uint256 public constant crowdsaleSupply = 1450 * 10 ** 24;
    uint256 public constant bountySupply = 245 * 10 ** 24;
    
    address public crowdsaleWallet;
    address public bountyWallet;
    address public siteAccount;

    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => uint256) balances;

        

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Contract constructor
     */
    constructor(address _crowdsaleWallet
                , address _bountyWallet
                , address _siteAccount) public {
        require(_crowdsaleWallet != address(0));
        require(_bountyWallet != address(0));
        require(_siteAccount != address(0));

        crowdsaleWallet = _crowdsaleWallet;
        bountyWallet = _bountyWallet;
        siteAccount = _siteAccount;

        // Issue 1450 millions crowdsale tokens
        _issueTokens(crowdsaleWallet, crowdsaleSupply);

        // Issue 245 millions bounty tokens
        _issueTokens(bountyWallet, bountySupply);


        allowed[crowdsaleWallet][siteAccount] = crowdsaleSupply;
        emit Approval(crowdsaleWallet, siteAccount, crowdsaleSupply);
        allowed[crowdsaleWallet][owner] = crowdsaleSupply;
        emit Approval(crowdsaleWallet, owner, crowdsaleSupply);
    }

    function _issueTokens(address _to, uint256 _amount) internal {
        require(balances[_to] == 0);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(address(0), _to, _amount);
    }


    modifier erc20Allowed() {
        require(state == State.Finalized || msg.sender == owner|| msg.sender == siteAccount || msg.sender == crowdsaleWallet);
        _;
    }

    modifier onlyOwnerOrSiteAccount() {
        require(msg.sender == owner || msg.sender == siteAccount);
        _;
    }
    
    function setSiteAccountAddress(address _address) public onlyOwner {
        require(_address != address(0));

        uint256 allowance = allowed[crowdsaleWallet][siteAccount];
        allowed[crowdsaleWallet][siteAccount] = 0;
        emit Approval(crowdsaleWallet, siteAccount, 0);
        allowed[crowdsaleWallet][_address] = allowed[crowdsaleWallet][_address].add(allowance);
        emit Approval(crowdsaleWallet, _address, allowed[crowdsaleWallet][_address]);
        siteAccount = _address;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }


    /**
     * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public erc20Allowed returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);


        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public erc20Allowed returns (bool) {
        return _transferFrom(msg.sender, _from, _to, _value);
    }

    function _transferFrom(address _who, address _from, address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);

        uint256 _allowance = allowed[_from][_who];

        require(_value <= _allowance);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][_who] = _allowance.sub(_value);


        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public erc20Allowed returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
    */
    function increaseApproval(address _spender, uint256 _addedValue) public erc20Allowed returns (bool) {
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
    */
    function decreaseApproval(address _spender, uint256 _subtractedValue) public erc20Allowed returns (bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
    */
    function burn(uint256 _value) public erc20Allowed {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

    function finalize() public onlyOwner {
        require(state == State.Active);
        require(now > startTime);
        state = State.Finalized;

        uint256 crowdsaleBalance = balanceOf(crowdsaleWallet);

        burnAmount = bountySupply.mul(crowdsaleBalance).div(crowdsaleSupply);
        _burn(bountyWallet, burnAmount);


        _burn(crowdsaleWallet, crowdsaleBalance);
    }
    
   
}
