pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./SponsorWhitelistControl.sol";

contract Treasure is IERC777Recipient {
    using SafeMath for uint256;

    address public owner;
    uint256 public TIME_STEP = 1 hours; 

    uint256 public BASE_NUM = 1000; 

    uint256 public rounds = 0;

    address public lastwinner;

    uint256 public lastTime; 

    uint256 public lastAmount;

    address public currentAddress;

    uint256 public currentAddressCount = 0;

    uint256 public currentTime = 0;

    uint256 public totalAmount; 

    uint256 public constant PERCENTS_DIVIDER = 1000; 
    uint256 public constant OWNER_PERCENT = 50; 

    mapping(address => uint256) public accountAmount;

    IERC777 _token;

    event NewAward(address indexed user, uint256 amount, uint256 time);
    event Involved(address indexed user, uint256 amount, uint256 time);

    IERC1820Registry private _erc1820 = IERC1820Registry(
        0x88887eD889e776bCBe2f0f9932EcFaBcDfCd1820
    );

    // keccak256("ERC777TokensRecipient")
    bytes32
        private constant TOKENS_RECIPIENT_INTERFACE_HASH = 0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

    //代付
    SponsorWhitelistControl public constant SPONSOR = SponsorWhitelistControl(
        address(0x0888000000000000000000000000000000000001)
    );

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor(IERC777 tokenAddress) public {
        _erc1820.setInterfaceImplementer(
            address(this),
            TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );

        owner = msg.sender;

        _token = tokenAddress;

        // register all users as sponsees
        address[] memory users = new address[](1);
        users[0] = address(0);
        SPONSOR.addPrivilege(users);
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {

        uint256 Ticket_Amount = currentAddressCount.div(BASE_NUM).mul(1 ether).add(1 ether);

        if (amount == Ticket_Amount) {

            totalAmount = totalAmount.add(amount);

            accountAmount[from] = accountAmount[from].add(amount);

            emit Involved(from, amount, block.timestamp);

            if(currentAddressCount > 0 && block.timestamp.sub(currentTime) > TIME_STEP){

                
                uint256 sumAmount = _token.balanceOf(address(this)).sub(amount);

                uint256 ownerDividends = sumAmount.mul(OWNER_PERCENT).div(
                    PERCENTS_DIVIDER
                );

                uint256 luckDividends = sumAmount.sub(ownerDividends);

                _token.send(currentAddress, luckDividends, "");
                _token.send(owner, ownerDividends, "");

    
                lastwinner = currentAddress;

                lastTime = block.timestamp;

                lastAmount = luckDividends;

                rounds = rounds.add(1);

                emit NewAward(currentAddress, luckDividends, block.timestamp);

                currentAddressCount = 0;

            }

            currentAddress = from;
            
            currentTime = block.timestamp;

            currentAddressCount = currentAddressCount.add(1);


        } else {
            _token.send(from, amount, "");
        }
    }


    
    function getTicketAmount() public view returns (uint256) {
        return currentAddressCount.div(BASE_NUM).mul(1 ether).add(1 ether);
    }

    
    function getCurrentAddressCount() public view returns (uint256) {
        return currentAddressCount;
    }

    
    function getTotalAmount() public view returns (uint256) {
        return totalAmount;
    }

    
    function getBalanceAmount() public view returns (uint256){
        return _token.balanceOf(address(this));
    }
    
    function getAccountAmount(address _account) public view returns (uint256){
        return accountAmount[_account];
    }
    
    function getRounds() public view returns (uint256) {
        return rounds;
    }

    
    function getLastwinner() public view returns (address) {
        return lastwinner;
    }
    
    function getLastTime() public view returns (uint256) {
        return lastTime;
    }
    
    function getLastAmount() public view returns (uint256) {
        return lastAmount;
    }

    
    function getCurrentAddress() public view returns (address) {
        return currentAddress;
    }
  
    function getCurrentTime() public view returns (uint256) {
        return currentTime;
    }

    function withdrawCFX() external onlyOwner {
        uint256 balance = address(this).balance;
        address(uint160(owner)).transfer(balance);
    }

    receive() external payable {}
}
