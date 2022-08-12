import { expect } from "chai";
import { ethers } from "hardhat";
import {
  SEAPORT_CONSIDERATION_FULFILLMENTS_TWO_ORDERS_DIFFERENT_COLLECTIONS,
  SEAPORT_EXTRA_DATA_SCHEMA,
  SEAPORT_OFFER_FULFILLMENT_TWO_ITEMS,
} from "../constants";
import getFixture from "./utils/get-fixture";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import deploySeaportFixture from "./fixtures/deploy-seaport-fixture";
import getSeaportOrderExtraData from "./utils/get-seaport-order-extra-data";
import getSeaportOrderJson from "./utils/get-seaport-order-json";
import combineConsiderationAmount from "./utils/combine-consideration-amount";

describe("Aggregator", () => {
  it("Should be able to handle multiple collections and multiple collection types", async function () {
    const { aggregator, buyer, proxy, functionSelector, bayc, cityDao } = await loadFixture(deploySeaportFixture);

    const cityDaoOrders = getFixture("city-dao-orders.json");
    const orderOne = getFixture("bayc-6092-order.json");
    const orderTwo = cityDaoOrders[1].protocol_data;

    const priceOne = combineConsiderationAmount(orderOne.parameters.consideration);
    const priceTwo = combineConsiderationAmount(orderTwo.parameters.consideration);
    const price = priceOne.add(priceTwo);

    const abiCoder = ethers.utils.defaultAbiCoder;
    const tradeData = [
      {
        proxy: proxy.address,
        selector: functionSelector,
        value: price,
        orders: [
          getSeaportOrderJson(orderOne, priceOne, buyer.address),
          getSeaportOrderJson(orderTwo, priceTwo, buyer.address),
        ],
        ordersExtraData: [getSeaportOrderExtraData(orderOne), getSeaportOrderExtraData(orderTwo)],
        extraData: abiCoder.encode(
          [SEAPORT_EXTRA_DATA_SCHEMA],
          [
            {
              offerFulfillments: SEAPORT_OFFER_FULFILLMENT_TWO_ITEMS,
              considerationFulfillments: SEAPORT_CONSIDERATION_FULFILLMENTS_TWO_ORDERS_DIFFERENT_COLLECTIONS,
            },
          ]
        ),
      },
    ];

    const tx = await aggregator.connect(buyer).buyWithETH(tradeData, { value: price });
    await tx.wait();

    expect(await bayc.balanceOf(buyer.address)).to.equal(1);
    expect(await cityDao.balanceOf(buyer.address, 42)).to.equal(1);
    expect(await bayc.ownerOf(6092)).to.equal(buyer.address);
  });
});
