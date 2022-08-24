import { expect } from "chai";
import { ethers } from "hardhat";
import {
  SEAPORT_CONSIDERATION_FULFILLMENTS_TWO_ORDERS_SAME_COLLECTION,
  SEAPORT_EXTRA_DATA_SCHEMA,
  SEAPORT_OFFER_FULFILLMENT_TWO_ITEMS,
} from "../constants";
import getFixture from "./utils/get-fixture";
import calculateTxFee from "./utils/calculate-tx-fee";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import deploySeaportFixture from "./fixtures/deploy-seaport-fixture";
import getSeaportOrderExtraData from "./utils/get-seaport-order-extra-data";
import getSeaportOrderJson from "./utils/get-seaport-order-json";
import combineConsiderationAmount from "./utils/combine-consideration-amount";
import validateSweepEvent from "./utils/validate-sweep-event";

describe("Aggregator", () => {
  it("Should be able to handle OpenSea trades (fulfillAvailableAdvancedOrders)", async function () {
    const { aggregator, buyer, proxy, functionSelector, cityDao } = await loadFixture(deploySeaportFixture);

    const orders = getFixture("seaport", "city-dao-orders.json");
    const orderOne = orders[0].protocol_data;
    const orderTwo = orders[1].protocol_data;

    const priceOne = combineConsiderationAmount(orderOne.parameters.consideration);
    const priceTwo = combineConsiderationAmount(orderTwo.parameters.consideration);
    const price = priceOne.add(priceTwo);

    const abiCoder = ethers.utils.defaultAbiCoder;
    const tradeData = [
      {
        proxy: proxy.address,
        selector: functionSelector,
        value: price,
        orders: [getSeaportOrderJson(orderOne, priceOne), getSeaportOrderJson(orderTwo, priceTwo)],
        ordersExtraData: [getSeaportOrderExtraData(orderOne), getSeaportOrderExtraData(orderTwo)],
        extraData: abiCoder.encode(
          [SEAPORT_EXTRA_DATA_SCHEMA],
          [
            {
              offerFulfillments: SEAPORT_OFFER_FULFILLMENT_TWO_ITEMS,
              considerationFulfillments: SEAPORT_CONSIDERATION_FULFILLMENTS_TWO_ORDERS_SAME_COLLECTION,
            },
          ]
        ),
      },
    ];

    const tx = await aggregator
      .connect(buyer)
      .buyWithETH(tradeData, buyer.address, false, { value: price.add(ethers.utils.parseEther("1")) });
    const receipt = await tx.wait();

    validateSweepEvent(receipt, buyer.address, 1, 1);

    expect(await cityDao.balanceOf(buyer.address, 42)).to.equal(2);
  });

  it("is able to refund extra ETH paid (not trickled down to SeaportProxy)", async function () {
    const { aggregator, buyer, proxy, functionSelector, cityDao } = await loadFixture(deploySeaportFixture);

    const orders = getFixture("seaport", "city-dao-orders.json");
    const orderOne = orders[0].protocol_data;
    const orderTwo = orders[1].protocol_data;

    const priceOne = combineConsiderationAmount(orderOne.parameters.consideration);
    const priceTwo = combineConsiderationAmount(orderTwo.parameters.consideration);
    const price = priceOne.add(priceTwo);

    const abiCoder = ethers.utils.defaultAbiCoder;
    const tradeData = [
      {
        proxy: proxy.address,
        selector: functionSelector,
        value: price,
        orders: [getSeaportOrderJson(orderOne, priceOne), getSeaportOrderJson(orderTwo, priceTwo)],
        ordersExtraData: [getSeaportOrderExtraData(orderOne), getSeaportOrderExtraData(orderTwo)],
        extraData: abiCoder.encode(
          [SEAPORT_EXTRA_DATA_SCHEMA],
          [
            {
              offerFulfillments: SEAPORT_OFFER_FULFILLMENT_TWO_ITEMS,
              considerationFulfillments: SEAPORT_CONSIDERATION_FULFILLMENTS_TWO_ORDERS_SAME_COLLECTION,
            },
          ]
        ),
      },
    ];

    const buyerBalanceBefore = await ethers.provider.getBalance(buyer.address);

    const tx = await aggregator
      .connect(buyer)
      .buyWithETH(tradeData, buyer.address, false, { value: price.add(ethers.constants.WeiPerEther) });
    const receipt = await tx.wait();
    const txFee = await calculateTxFee(tx);

    validateSweepEvent(receipt, buyer.address, 1, 1);

    expect(await cityDao.balanceOf(buyer.address, 42)).to.equal(2);
    expect(await ethers.provider.getBalance(aggregator.address)).to.equal(0);
    const buyerBalanceAfter = await ethers.provider.getBalance(buyer.address);
    expect(buyerBalanceBefore.sub(buyerBalanceAfter).sub(txFee)).to.equal(price);
  });

  it("is able to refund extra ETH paid (trickled down to SeaportProxy)", async function () {
    const { aggregator, buyer, proxy, functionSelector, cityDao } = await loadFixture(deploySeaportFixture);

    const orders = getFixture("seaport", "city-dao-orders.json");
    const orderOne = orders[0].protocol_data;
    const orderTwo = orders[1].protocol_data;

    const { WeiPerEther } = ethers.constants;
    const priceOne = WeiPerEther;
    const priceTwo = WeiPerEther;
    const price = priceOne.add(priceTwo);

    const abiCoder = ethers.utils.defaultAbiCoder;
    const tradeData = [
      {
        proxy: proxy.address,
        selector: functionSelector,
        value: price,
        orders: [getSeaportOrderJson(orderOne, priceOne), getSeaportOrderJson(orderTwo, priceTwo)],
        ordersExtraData: [getSeaportOrderExtraData(orderOne), getSeaportOrderExtraData(orderTwo)],
        extraData: abiCoder.encode(
          [SEAPORT_EXTRA_DATA_SCHEMA],
          [
            {
              offerFulfillments: SEAPORT_OFFER_FULFILLMENT_TWO_ITEMS,
              considerationFulfillments: SEAPORT_CONSIDERATION_FULFILLMENTS_TWO_ORDERS_SAME_COLLECTION,
            },
          ]
        ),
      },
    ];

    const buyerBalanceBefore = await ethers.provider.getBalance(buyer.address);

    const tx = await aggregator.connect(buyer).buyWithETH(tradeData, buyer.address, false, { value: price });
    const receipt = await tx.wait();
    const txFee = await calculateTxFee(tx);

    validateSweepEvent(receipt, buyer.address, 1, 1);

    expect(await cityDao.balanceOf(buyer.address, 42)).to.equal(2);
    expect(await ethers.provider.getBalance(aggregator.address)).to.equal(0);
    const buyerBalanceAfter = await ethers.provider.getBalance(buyer.address);
    const actualPriceOne = combineConsiderationAmount(orderOne.parameters.consideration);
    const actualPriceTwo = combineConsiderationAmount(orderTwo.parameters.consideration);
    expect(buyerBalanceBefore.sub(buyerBalanceAfter).sub(txFee)).to.equal(actualPriceOne.add(actualPriceTwo));
  });
});
