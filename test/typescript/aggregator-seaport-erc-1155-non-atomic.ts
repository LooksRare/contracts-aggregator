import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import getFixture from "./utils/get-fixture";
import getSeaportOrderExtraData from "./utils/get-seaport-order-extra-data";
import getSeaportOrderJson from "./utils/get-seaport-order-json";
import combineConsiderationAmount from "./utils/combine-consideration-amount";
import validateSweepEvent from "./utils/validate-sweep-event";
import deploySeaportFixture from "./fixtures/deploy-seaport-fixture";
import behavesLikeSeaportERC1155 from "./shared-tests/behaves-like-seaport-erc-1155";

describe("Aggregator", () => {
  behavesLikeSeaportERC1155(false);

  it("Should be able to handle OpenSea trades non-atomically", async function () {
    const { aggregator, buyer, proxy, functionSelector, cityDao } = await loadFixture(deploySeaportFixture);
    const { HashZero, Zero } = ethers.constants;

    const orders = getFixture("seaport", "city-dao-orders.json");
    const orderOne = orders[0];
    const orderTwo = orders[1];

    const priceOne = combineConsiderationAmount(orderOne.parameters.consideration);
    const priceTwo = Zero; // not paying for the second order
    const price = priceOne.add(priceTwo);

    const tradeData = [
      {
        proxy: proxy.address,
        selector: functionSelector,
        value: price,
        maxFeeBp: 0,
        orders: [getSeaportOrderJson(orderOne), getSeaportOrderJson(orderTwo)],
        ordersExtraData: [getSeaportOrderExtraData(orderOne), getSeaportOrderExtraData(orderTwo)],
        extraData: HashZero,
      },
    ];

    const tx = await aggregator
      .connect(buyer)
      .execute([], tradeData, buyer.address, buyer.address, false, { value: price });
    const receipt = await tx.wait();

    validateSweepEvent(receipt, buyer.address);

    expect(await cityDao.balanceOf(buyer.address, 42)).to.equal(1);
  });
});
