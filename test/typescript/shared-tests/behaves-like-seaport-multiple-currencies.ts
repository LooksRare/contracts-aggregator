import { ethers } from "hardhat";
import getFixture from "../utils/get-fixture";
import deploySeaportFixture from "../fixtures/deploy-seaport-fixture";
import combineConsiderationAmount from "../utils/combine-consideration-amount";
import getSeaportOrderJson from "../utils/get-seaport-order-json";
import getSeaportOrderExtraData from "../utils/get-seaport-order-extra-data";
import {
  SEAPORT_EXTRA_DATA_SCHEMA,
  SEAPORT_OFFER_FULFILLMENT_TWO_ITEMS,
  USDC,
  SEAPORT_CONSIDERATION_FULFILLMENTS_TWO_ORDERS_DIFFERENT_CURRENCIES,
  USDC_DECIMALS,
} from "../../constants";
import validateSweepEvent from "../utils/validate-sweep-event";
import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import airdropUSDC from "../utils/airdrop-usdc";

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

export default function behavesLikeSeaportMultipleCurrencies(isAtomic: boolean): void {
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

    const tokenTransfers = [{ amount: priceOne, currency: USDC }];
    const tradeData = [
      {
        tokenTransfers,
        proxy: proxy.address,
        selector: functionSelector,
        value: priceTwo,
        orders: [getSeaportOrderJson(orderOne, priceOne), getSeaportOrderJson(orderTwo, priceTwo)],
        ordersExtraData: [getSeaportOrderExtraData(orderOne), getSeaportOrderExtraData(orderTwo)],
        extraData: isAtomic ? encodedExtraData() : ethers.constants.HashZero,
      },
    ];

    const tx = await aggregator
      .connect(buyer)
      .execute(tokenTransfers, tradeData, buyer.address, isAtomic, { value: priceTwo });
    const receipt = await tx.wait();

    validateSweepEvent(receipt, buyer.address, 1, 1);

    expect(await bayc.balanceOf(buyer.address)).to.equal(2);
    expect(await bayc.ownerOf(9996)).to.equal(buyer.address);
    expect(await bayc.ownerOf(5509)).to.equal(buyer.address);

    expect(await usdc.balanceOf(buyer.address)).to.equal(0);
    expect(await usdc.allowance(buyer.address, aggregator.address)).to.equal(0);
  });

  it("Should be able to refund extra ERC-20 tokens paid", async function () {
    const { aggregator, buyer, proxy, functionSelector, bayc } = await loadFixture(deploySeaportFixture);

    const orderOne = getFixture("seaport", "bayc-9996-order.json");
    const orderTwo = getFixture("seaport", "bayc-5509-order.json");

    // priceOne is in USDC and priceTwo is in ETH
    const priceOne = combineConsiderationAmount(orderOne.parameters.consideration);
    const priceTwo = combineConsiderationAmount(orderTwo.parameters.consideration);

    // Doesn't look good here but the buyer is the first address, meaning the contract deployer/owner
    await proxy.connect(buyer).approve(USDC);

    const excess = ethers.utils.parseUnits("100", USDC_DECIMALS);

    await airdropUSDC(buyer.address, priceOne.add(excess));

    const usdc = await ethers.getContractAt("IERC20", USDC);
    await usdc.connect(buyer).approve(aggregator.address, priceOne.add(excess));

    const tokenTransfers = [{ amount: priceOne.add(excess), currency: USDC }];
    const tradeData = [
      {
        tokenTransfers,
        proxy: proxy.address,
        selector: functionSelector,
        value: priceTwo,
        orders: [getSeaportOrderJson(orderOne, priceOne), getSeaportOrderJson(orderTwo, priceTwo)],
        ordersExtraData: [getSeaportOrderExtraData(orderOne), getSeaportOrderExtraData(orderTwo)],
        extraData: isAtomic ? encodedExtraData() : ethers.constants.HashZero,
      },
    ];

    const tx = await aggregator
      .connect(buyer)
      .execute(tokenTransfers, tradeData, buyer.address, isAtomic, { value: priceTwo });
    const receipt = await tx.wait();

    validateSweepEvent(receipt, buyer.address, 1, 1);

    expect(await bayc.balanceOf(buyer.address)).to.equal(2);
    expect(await bayc.ownerOf(9996)).to.equal(buyer.address);
    expect(await bayc.ownerOf(5509)).to.equal(buyer.address);

    expect(await usdc.balanceOf(aggregator.address)).to.equal(0);
    expect(await usdc.balanceOf(proxy.address)).to.equal(0);
    expect(await usdc.balanceOf(buyer.address)).to.equal(excess);
    expect(await usdc.allowance(buyer.address, aggregator.address)).to.equal(0);
  });

  it("Should be able to charge a fee", async function () {
    const { aggregator, buyer, proxy, functionSelector, bayc } = await loadFixture(deploySeaportFixture);
    const { getBalance } = ethers.provider;

    const [, protocolFeeRecipient] = await ethers.getSigners();

    const orderOne = getFixture("seaport", "bayc-9996-order.json");
    const orderTwo = getFixture("seaport", "bayc-5509-order.json");

    // priceOne is in USDC and priceTwo is in ETH
    const priceOneBeforeFee = combineConsiderationAmount(orderOne.parameters.consideration);
    const priceOne = priceOneBeforeFee.mul(10250).div(10000); // Fee
    const priceTwoBeforeFee = combineConsiderationAmount(orderTwo.parameters.consideration);
    const priceTwo = priceTwoBeforeFee.mul(10250).div(10000); // Fee

    // Doesn't look good here but the buyer is the first address, meaning the contract deployer/owner
    await proxy.connect(buyer).setFeeBp(250);
    await proxy.connect(buyer).setFeeRecipient(protocolFeeRecipient.address);
    await proxy.connect(buyer).approve(USDC);

    await airdropUSDC(buyer.address, priceOne);

    const usdc = await ethers.getContractAt("IERC20", USDC);
    await usdc.connect(buyer).approve(aggregator.address, priceOne);

    const tokenTransfers = [{ amount: priceOne, currency: USDC }];
    const tradeData = [
      {
        tokenTransfers,
        proxy: proxy.address,
        selector: functionSelector,
        value: priceTwo,
        orders: [getSeaportOrderJson(orderOne, priceOneBeforeFee), getSeaportOrderJson(orderTwo, priceTwoBeforeFee)],
        ordersExtraData: [getSeaportOrderExtraData(orderOne), getSeaportOrderExtraData(orderTwo)],
        extraData: isAtomic ? encodedExtraData() : ethers.constants.HashZero,
      },
    ];

    const feeRecipientUsdcBalanceBefore = await usdc.balanceOf(protocolFeeRecipient.address);
    const feeRecipientEthBalanceBefore = await getBalance(protocolFeeRecipient.address);

    const tx = await aggregator
      .connect(buyer)
      .execute(tokenTransfers, tradeData, buyer.address, isAtomic, { value: priceTwo });
    const receipt = await tx.wait();

    validateSweepEvent(receipt, buyer.address, 1, 1);

    const feeRecipientUsdcBalanceAfter = await usdc.balanceOf(protocolFeeRecipient.address);
    const feeRecipientEthBalanceAfter = await getBalance(protocolFeeRecipient.address);

    expect(feeRecipientUsdcBalanceAfter.sub(feeRecipientUsdcBalanceBefore)).to.equal(priceOne.sub(priceOneBeforeFee));
    expect(feeRecipientEthBalanceAfter.sub(feeRecipientEthBalanceBefore)).to.equal(priceTwo.sub(priceTwoBeforeFee));

    expect(await bayc.balanceOf(buyer.address)).to.equal(2);
    expect(await bayc.ownerOf(9996)).to.equal(buyer.address);
    expect(await bayc.ownerOf(5509)).to.equal(buyer.address);

    expect(await usdc.balanceOf(buyer.address)).to.equal(0);
    expect(await usdc.allowance(buyer.address, aggregator.address)).to.equal(0);
  });
}
