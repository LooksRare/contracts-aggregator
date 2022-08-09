// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "../interfaces/ILooksRareV1.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {BasicOrder} from "../libraries/OrderStructs.sol";

import "hardhat/console.sol";

contract LooksRareV2Proxy {
    enum ItemType {
        ERC721,
        ERC1155
    }
    struct OrderExtraData {
        address strategy;
        uint256 nonce;
        uint256 minPercentageToAsk;
    }

    ILooksRareV1 constant MARKETPLACE = ILooksRareV1(0x59728544B08AB483533076417FbBB2fD0B17CE3a);
    bytes4 constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    error InvalidOrderLength();
    error InvalidSignature();
    error UnrecognizedTokenInterface();
    error ZeroAddress();

    function buyWithETH(
        BasicOrder[] calldata orders,
        bytes[] calldata ordersExtraData,
        bytes memory
    ) external payable {
        uint256 ordersLength = orders.length;
        if (ordersLength == 0 || ordersLength != ordersExtraData.length) revert InvalidOrderLength();
        for (uint256 i; i < ordersLength; ) {
            if (orders[i].recipient == address(0)) revert ZeroAddress();

            uint256 amount;
            ItemType itemType;

            BasicOrder memory order = orders[i];

            // TODO: handle CryptoPunks/Mooncats
            if (IERC165(order.collection).supportsInterface(INTERFACE_ID_ERC721)) {
                amount = 1;
                itemType = ItemType.ERC721;
            } else if (IERC165(order.collection).supportsInterface(INTERFACE_ID_ERC1155)) {
                amount = order.amount;
                itemType = ItemType.ERC1155;
            } else {
                revert UnrecognizedTokenInterface();
            }

            OrderExtraData memory orderExtraData = abi.decode(ordersExtraData[i], (OrderExtraData));

            ILooksRareV1.MakerOrder memory makerAsk;
            makerAsk.isOrderAsk = true;
            makerAsk.signer = order.signer;
            makerAsk.collection = order.collection;
            makerAsk.tokenId = order.tokenId;
            makerAsk.price = order.price;
            makerAsk.amount = amount;
            makerAsk.strategy = orderExtraData.strategy;
            makerAsk.nonce = orderExtraData.nonce;
            makerAsk.minPercentageToAsk = orderExtraData.minPercentageToAsk;
            makerAsk.currency = order.currency;
            makerAsk.startTime = order.startTime;
            makerAsk.endTime = order.endTime;

            (uint8 v, bytes32 r, bytes32 s) = splitSignature(order.signature);
            makerAsk.v = v;
            makerAsk.r = r;
            makerAsk.s = s;

            ILooksRareV1.TakerOrder memory takerBid;
            takerBid.isOrderAsk = false;
            takerBid.taker = address(this);
            takerBid.price = order.price;
            takerBid.tokenId = order.tokenId;
            takerBid.minPercentageToAsk = orderExtraData.minPercentageToAsk;

            _matchSingleOrder(takerBid, makerAsk, order.recipient, itemType);

            unchecked {
                ++i;
            }
        }
    }

    function _matchSingleOrder(
        ILooksRareV1.TakerOrder memory takerBid,
        ILooksRareV1.MakerOrder memory makerAsk,
        address recipient,
        ItemType itemType
    ) private {
        try MARKETPLACE.matchAskWithTakerBidUsingETHAndWETH{value: makerAsk.price}(takerBid, makerAsk) {
            // TODO: handle CryptoPunks/Mooncats
            if (itemType == ItemType.ERC721) {
                IERC721(makerAsk.collection).transferFrom(address(this), recipient, makerAsk.tokenId);
            } else if (itemType == ItemType.ERC1155) {
                IERC1155(makerAsk.collection).safeTransferFrom(
                    address(this),
                    recipient,
                    makerAsk.tokenId,
                    makerAsk.amount,
                    "0x"
                );
            }
        } catch (bytes memory returnData) {
            if (returnData.length > 0) {
                assembly {
                    let returnDataSize := mload(returnData)
                    revert(add(32, returnData), returnDataSize)
                }
            } else {}
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    // TODO: move to a library
    function splitSignature(bytes memory sig)
        private
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        if (sig.length != 65) revert InvalidSignature();

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }
}
