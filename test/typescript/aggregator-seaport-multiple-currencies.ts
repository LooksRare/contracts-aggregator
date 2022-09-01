import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import {
  SEAPORT_CONSIDERATION_FULFILLMENTS_TWO_ORDERS_DIFFERENT_CURRENCIES,
  SEAPORT_EXTRA_DATA_SCHEMA,
  SEAPORT_OFFER_FULFILLMENT_TWO_ITEMS,
  USDC,
} from "../constants";
import deploySeaportFixture from "./fixtures/deploy-seaport-fixture";
import airdropUSDC from "./utils/airdrop-usdc";
import combineConsiderationAmount from "./utils/combine-consideration-amount";
import getFixture from "./utils/get-fixture";
import getSeaportOrderExtraData from "./utils/get-seaport-order-extra-data";
import getSeaportOrderJson from "./utils/get-seaport-order-json";
import validateSweepEvent from "./utils/validate-sweep-event";

const encodedExtraData = () => {
  const abiCoder = ethers.utils.defaultAbiCoder;
  return abiCoder.encode(
    [SEAPORT_EXTRA_DATA_SCHEMA],
    [
      {
        offerFulfillments: SEAPORT_OFFER_FULFILLMENT_TWO_ITEMS,
        considerationFulfillments: SEAPORT_CONSIDERATION_FULFILLMENTS_TWO_ORDERS_DIFFERENT_CURRENCIES,
      },
    ]
  );
};

describe("Aggregator", () => {
  it("Should be able to handle OpenSea trades", async function () {
    const { aggregator, buyer, proxy, functionSelector, bayc } = await loadFixture(deploySeaportFixture);

    const orderOne = getFixture("seaport", "bayc-9996-order.json");
    const orderTwo = getFixture("seaport", "bayc-5509-order.json");

    // priceOne is in USDC and priceTwo is in ETH
    const priceOne = combineConsiderationAmount(orderOne.parameters.consideration);
    const priceTwo = combineConsiderationAmount(orderTwo.parameters.consideration);

    // Doesn't look good here but the buyer is the first address, meaning the contract deployer/owner
    await proxy.connect(buyer).approve(USDC);

    await airdropUSDC(buyer.address, priceOne);

    const usdc = await ethers.getContractAt("IERC20", USDC);
    await usdc.connect(buyer).approve(aggregator.address, priceOne);

    const tradeData = [
      {
        tokenTransfers: [{ amount: priceOne, currency: USDC }],
        proxy: proxy.address,
        selector: functionSelector,
        value: priceTwo,
        orders: [getSeaportOrderJson(orderOne, priceOne), getSeaportOrderJson(orderTwo, priceTwo)],
        ordersExtraData: [getSeaportOrderExtraData(orderOne), getSeaportOrderExtraData(orderTwo)],
        extraData: encodedExtraData(),
        // extraData: ethers.constants.HashZero,
      },
    ];

    const tx = await aggregator.connect(buyer).execute(tradeData, buyer.address, true, { value: priceTwo });
    const receipt = await tx.wait();

    validateSweepEvent(receipt, buyer.address, 1, 1);

    expect(await bayc.balanceOf(buyer.address)).to.equal(2);
    expect(await bayc.ownerOf(9996)).to.equal(buyer.address);
    expect(await bayc.ownerOf(5509)).to.equal(buyer.address);
  });
});