import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import {
  SEAPORT_CONSIDERATION_FULFILLMENTS_TWO_ORDERS_SAME_COLLECTION,
  SEAPORT_EXTRA_DATA_SCHEMA,
  SEAPORT_OFFER_FULFILLMENT_TWO_ITEMS,
} from "../constants";
import deploySeaportFixture from "./fixtures/deploy-seaport-fixture";
import combineConsiderationAmount from "./utils/combine-consideration-amount";
import getFixture from "./utils/get-fixture";
import getSeaportOrderExtraData from "./utils/get-seaport-order-extra-data";
import getSeaportOrderJson from "./utils/get-seaport-order-json";
import behavesLikeSeaportERC721 from "./shared-tests/behaves-like-seaport-erc721";

const encodedExtraData = () => {
  const abiCoder = ethers.utils.defaultAbiCoder;
  return abiCoder.encode(
    [SEAPORT_EXTRA_DATA_SCHEMA],
    [
      {
        offerFulfillments: SEAPORT_OFFER_FULFILLMENT_TWO_ITEMS,
        considerationFulfillments: SEAPORT_CONSIDERATION_FULFILLMENTS_TWO_ORDERS_SAME_COLLECTION,
      },
    ]
  );
};

describe("Aggregator", () => {
  before(async () => {
    await ethers.provider.send("hardhat_reset", [
      {
        forking: {
          jsonRpcUrl: process.env.ETH_RPC_URL,
          blockNumber: 15300884,
        },
      },
    ]);
  });

  behavesLikeSeaportERC721(true);

  it("Should revert if one of the trades is cancelled", async function () {
    const { aggregator, buyer, proxy, functionSelector } = await loadFixture(deploySeaportFixture);

    const orderOne = getFixture("seaport", "bayc-2518-order.json");
    const orderTwo = getFixture("seaport", "bayc-8498-order.json");

    const priceOne = combineConsiderationAmount(orderOne.parameters.consideration);
    const priceTwo = combineConsiderationAmount(orderTwo.parameters.consideration);
    const price = priceOne.add(priceTwo);

    const tradeData = [
      {
        proxy: proxy.address,
        selector: functionSelector,
        value: price,
        maxFeeBp: 0,
        orders: [getSeaportOrderJson(orderOne), getSeaportOrderJson(orderTwo)],
        ordersExtraData: [getSeaportOrderExtraData(orderOne), getSeaportOrderExtraData(orderTwo)],
        extraData: encodedExtraData(),
      },
    ];

    // Make the 2nd order expire
    await ethers.provider.send("evm_setNextBlockTimestamp", [Number(orderTwo.parameters.endTime) + 1]);

    await expect(
      aggregator.connect(buyer).execute([], tradeData, buyer.address, buyer.address, true, { value: price })
    ).to.be.revertedWith("TradeExecutionFailed()");
  });
});
