pragma solidity >=0.5.0 <0.6.0;

import "../common/Controlled.sol";
import "../common/MessageSigned.sol";

/**
 * @notice Defines tribute to talk
 */
contract MessageTribute is Controlled, MessageSigned {
    event SetTribute(address indexed account, address beneficiary, uint256 value);
    bool public stopped;
    struct Tribute {
        address beneficiary;
        uint256 value;
    }
    mapping(address => Tribute) tributeCatalog;

    /**
     * @notice Set tribute of account
     * @param _value Required tribute value
     * @param _beneficiary Account willing to receive payments
     */
    function setTribute(address _beneficiary, uint256 _value) external {
         setTribute(msg.sender, _beneficiary, _value);
    }

    /**
     * @notice Set tribute of account using signature
     * @param _beneficiary Account willing to receive payments
     * @param _value Required tribute value
     * @param _ttl TTL of message
     * @param _messageSignature signature of hashTributeMessage(_value, _ttl)
     */
    function setTribute(address _beneficiary, uint256 _value, uint256 _ttl, bytes calldata _messageSignature) external {
        uint256 time = block.timestamp;
        require(time < _ttl && _ttl-time < 1 days, "Invalid TTL");
        address signer = recoverAddress(getSignHash(hashTributeMessage(_beneficiary, _value, _ttl)), _messageSignature);
        require(signer != address(0), "Invalid signer");
        setTribute(signer, _beneficiary, _value);

    }

    /**
     * @notice Stops the contract of being able to change values.
     */
    function setStopped(bool _stopped) external onlyController {
        stopped = _stopped;
    }

    /**
     * @notice Obtain required tribute to talk with `_of`
     * @param _of Account to lookup
     * @return payment address and value of tribute
     */
    function getTribute(address _of) external view
        returns (address, uint256)
    {
        Tribute memory tribute = tributeCatalog[_of];
        return (tribute.beneficiary, tribute.value);
    }

    /**
     * @notice generates hash for signing tributes
     * @param _beneficiary Account willing to receive payments
     * @param _value Required tribute value
     * @param _ttl TTL of message
     */
    function hashTributeMessage(address _beneficiary, uint256 _value, uint256 _ttl) public view returns(bytes32) {
        return keccak256(abi.encodePacked(address(this), _beneficiary, _value, _ttl));
    }
    /**
     * @notice Changes tribute of account
     * @param _of Account chaning tribute
     * @param _beneficiary Account willing to receive payments
     * @param _value New tribute value
     */
    function setTribute(address _of, address _beneficiary, uint256 _value) internal {
        require(!stopped, "Contract stopped by Controller");
        tributeCatalog[_of] = Tribute({beneficiary: _beneficiary, value: _value});
        emit SetTribute(_of, _beneficiary, _value);
    }

}