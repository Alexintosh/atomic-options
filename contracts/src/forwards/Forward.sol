pragma solidity >=0.4.21 <0.6.0;

import "../../lib/openzeppelin-solidity/ERC20.sol";
import "../parent_contracts/DerivativeCommon.sol";

/**
 * @title Forward
 * @dev Basic Forward
 */
contract Forward is DerivativeCommon {
  // // Strike price [i.e. (strike_price_quote * base_volume) / strike_price_base  = asset_volume]
  uint256 public strike_price_base;
  uint256 public strike_price_quote;

  // Volume of the base token held
  uint256 public base_volume;

  constructor(address _issuer, address _buyer,
              address _base_addr, address _asset_addr,
              uint256 _strike_price_base, uint256 _strike_price_quote,
              uint256 _volume,
              uint256 _maturity_time)
    DerivativeCommon(_issuer, _buyer,
                    _base_addr, _asset_addr,
                    _volume,
                    _maturity_time) public {
    strike_price_base = _strike_price_base;
    strike_price_quote = _strike_price_quote;
    base_volume = (volume * strike_price_base) / strike_price_quote;
  }

  function activate() public {
    require(msg.sender == buyer);
    require(state == STATE_COLLATERALIZED);
    bool base_transfer = base.transferFrom(buyer, address(this), base_volume);
    require(base_transfer);

    state = STATE_ACTIVE;
  }

  // Executes the forward trade
  function settle() public {
    require((msg.sender == buyer) || (msg.sender == issuer));
    require(maturity_time <= block.timestamp);
    require(volume > 0);

    bool asset_transfer = asset.transfer(buyer, volume);
    require(asset_transfer);
    bool base_transfer = base.transfer(issuer, base_volume);
    require(base_transfer);

    volume = 0;
    base_volume = 0;

    state = STATE_EXPIRED;
  }

  // In a forward, only really useful for aborting
  // Conditions and call mostly kept consistent with OptionCommon
  function expire() public {
    require(msg.sender == issuer);
    require(state == STATE_COLLATERALIZED);
    require(state != STATE_EXPIRED);

    bool asset_transfer = asset.transfer(issuer, volume);
    require(asset_transfer);

    state = STATE_EXPIRED;
  }

  // Returns all information about the contract in one go
  function get_info() public view returns (address, address, address, address,
                                            uint256, uint256,
                                            uint256, uint256,
                                            uint256, uint256) {
    return(issuer, buyer, base_addr, asset_addr,
            strike_price_base, strike_price_quote,
            volume, base_volume,
            maturity_time, state);
  }
}
