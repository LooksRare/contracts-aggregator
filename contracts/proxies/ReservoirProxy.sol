// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Interfaces
import {IProxy} from "../interfaces/IProxy.sol";
import {IReservoirRouter} from "../interfaces/IReservoirRouter.sol";

// Libraries
import {BasicOrder} from "../libraries/OrderStructs.sol";

// Shared errors
import {InvalidOrderLength} from "../libraries/SharedErrors.sol";

contract ReservoirProxy is IProxy {
    address public immutable marketplace;
    address public immutable aggregator;

    /**
     * @param _marketplace Reservoir's address
     * @param _aggregator LooksRareAggregator's address
     */
    constructor(address _marketplace, address _aggregator) {
        marketplace = _marketplace;
        aggregator = _aggregator;
    }

    /**
     * @notice Execute NFT sweeps through Reservoir in a single transaction
     * @param extraData Extra data for the whole transaction
     */
    function execute(
        BasicOrder[] calldata orders,
        bytes[] calldata, /* ordersExtraData */
        bytes calldata extraData,
        address, /* recipient */
        bool /* isAtomic */
    ) external payable override {
        if (address(this) != aggregator) {
            revert InvalidCaller();
        }

        if (orders.length != 1) {
            revert InvalidOrderLength();
        }

        marketplace.call{value: orders[0].price}(extraData);
    }
}
