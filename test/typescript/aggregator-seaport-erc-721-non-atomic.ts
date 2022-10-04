import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import deploySeaportFixture from "./fixtures/deploy-seaport-fixture";
import getFixture from "./utils/get-fixture";
import getSeaportOrderExtraData from "./utils/get-seaport-order-extra-data";
import getSeaportOrderJson from "./utils/get-seaport-order-json";
import combineConsiderationAmount from "./utils/combine-consideration-amount";
import validateSweepEvent from "./utils/validate-sweep-event";
import behavesLikeSeaportERC721 from "./shared-tests/behaves-like-seaport-erc-721";

describe("Aggregator", () => {
  behavesLikeSeaportERC721(false);

  it("Should be able to handle OpenSea trades non-atomically", async function () {
    const { aggregator, buyer, proxy, functionSelector, bayc } = await loadFixture(deploySeaportFixture);
    const { HashZero, Zero } = ethers.constants;

    const orderOne = getFixture("seaport", "bayc-2518-order.json");
    const orderTwo = getFixture("seaport", "bayc-8498-order.json");

    const priceOne = combineConsiderationAmount(orderOne.parameters.consideration);
    const priceTwo = Zero; // not paying for the second order
    const price = priceOne.add(priceTwo);

    const tradeData = [
      {
        proxy: proxy.address,
        selector: functionSelector,
        value: price,
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

    expect(await bayc.balanceOf(buyer.address)).to.equal(1);
    expect(await bayc.ownerOf(2518)).to.equal(buyer.address);
    expect(await bayc.ownerOf(8498)).to.not.equal(buyer.address);
  });
});
