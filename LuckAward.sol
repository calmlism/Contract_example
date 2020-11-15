pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./SponsorWhitelistControl.sol";

contract LuckAward is IERC777Recipient {
    using SafeMath for uint256;

    address public owner;

    uint256 public limitAmount = 20;

    uint256 public Ticket_Amount = 1 ether;

    address[] Participants;

    address public lastwinner;

    uint256 public lastTime;

    uint256 public rounds;

    uint256 public totalAmount;

    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant OWNER_PERCENT = 50;

    IERC777 _token;

    event NewLuckAward(address indexed user, uint256 amount, uint256 time);

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
        if (amount == Ticket_Amount) {
            totalAmount = totalAmount.add(amount);

            Participants.push(from);

            if (Participants.length == limitAmount) {
                address luckAddress = Participants[rand(limitAmount)];

                uint256 sumAmount = limitAmount.mul(Ticket_Amount);

                uint256 ownerDividends = sumAmount.mul(OWNER_PERCENT).div(
                    PERCENTS_DIVIDER
                );

                uint256 luckDividends = sumAmount.sub(ownerDividends);

                _token.send(from, luckDividends, "");
                _token.send(owner, ownerDividends, "");

                lastwinner = luckAddress;

                lastTime = block.timestamp;

                rounds = rounds.add(1);

                emit NewLuckAward(luckAddress, luckDividends, block.timestamp);

                delete Participants;
            }
        } else {
            _token.send(from, amount, "");
        }
    }

    function rand(uint256 _length) public view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    (block.timestamp) +
                        (block.difficulty) +
                        (block.gaslimit) +
                        (block.number),
                    now
                )
            )
        ) % 1000000;

        return random % _length;
    }

    function setLimitAmount(uint256 _limitAmount) external onlyOwner {
        limitAmount = _limitAmount;
    }

    function setTicketAmount(uint256 _ticketAmount) external onlyOwner {
        Ticket_Amount = _ticketAmount;
    }

    function getlimitAmount() public view returns (uint256) {
        return limitAmount;
    }

    function getTicketAmount() public view returns (uint256) {
        return Ticket_Amount;
    }

    function getRounds() public view returns (uint256) {
        return rounds;
    }

    function getTotalAmount() public view returns (uint256) {
        return totalAmount;
    }

    function getParticipants() public view returns (address[] memory) {
        return Participants;
    }

    function getLastwinner() public view returns (address) {
        return lastwinner;
    }

    function getLastTime() public view returns (uint256) {
        return lastTime;
    }

    function withdrawCFX() external onlyOwner {
        uint256 balance = address(this).balance;
        address(uint160(owner)).transfer(balance);
    }

    receive() external payable {}
}
