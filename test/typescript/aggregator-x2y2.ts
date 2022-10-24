import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import deployX2Y2Fixture from "./fixtures/deploy-x2y2-fixture";
import { BAYC, PARALLEL, X2Y2_ORDER_EXTRA_DATA_SCHEMA } from "../constants";
import { BigNumber } from "ethers";
import { expect } from "chai";
import getFixture from "./utils/get-fixture";
import { Fee, RunInput, X2Y2Order } from "@x2y2-io/sdk/src/types";
import calculateTxFee from "./utils/calculate-tx-fee";
import validateSweepEvent from "./utils/validate-sweep-event";

describe("LooksRareAggregator", () => {
  const tokenIdOne = "2674";
  const tokenIdTwo = "2491";
  const tokenIdThree = "10327";
  const tokenIdFour = "10511";

  const joinSignature = (order: X2Y2Order): string => {
    return ethers.utils.joinSignature({
      r: order.r,
      s: order.s,
      recoveryParam: order.v === 28 ? 1 : 0,
      v: order.v,
    });
  };

  const getX2Y2ExtraData = (order: RunInput): string => {
    const abiCoder = ethers.utils.defaultAbiCoder;
    return abiCoder.encode(
      [X2Y2_ORDER_EXTRA_DATA_SCHEMA],
      [
        {
          salt: BigNumber.from(order.orders[0].salt),
          itemData: order.orders[0].items[0].data,
          inputSalt: BigNumber.from(order.shared.salt),
          inputDeadline: BigNumber.from(order.shared.deadline),
          executionDelegate: order.details[0].executionDelegate,
          inputV: order.v,
          inputR: order.r,
          inputS: order.s,
          fees: order.details[0].fees.map((fee: Fee) => {
            return { percentage: BigNumber.from(fee.percentage), to: fee.to };
          }),
        },
      ]
    );
  };

  before(async () => {
    await ethers.provider.send("hardhat_reset", [
      {
        forking: {
          jsonRpcUrl: process.env.ETH_RPC_URL,
          blockNumber: 15346990,
        },
      },
    ]);
  });

  it("Should be able to handle X2Y2 trades", async function () {
    const { aggregator, proxy, functionSelector, buyer, bayc, parallel } = await loadFixture(deployX2Y2Fixture);

    const { AddressZero, HashZero } = ethers.constants;

    // BLOCK 15346990

    const orderOne = getFixture("x2y2", `bayc-${tokenIdOne}-run-input.json`);
    const orderTwo = getFixture("x2y2", `bayc-${tokenIdTwo}-run-input.json`);
    const orderThree = getFixture("x2y2", `parallel-${tokenIdThree}-run-input.json`);
    const orderFour = getFixture("x2y2", `parallel-${tokenIdFour}-run-input.json`);

    const priceOne = BigNumber.from(orderOne.details[0].price);
    const priceTwo = BigNumber.from(orderTwo.details[0].price);
    const priceThree = BigNumber.from(orderThree.details[0].price);
    const priceFour = BigNumber.from(orderFour.details[0].price);

    const totalValue = priceOne.add(priceTwo).add(priceThree).add(priceFour);

    const tx = await aggregator.connect(buyer).execute(
      [],
      [
        {
          proxy: proxy.address,
          selector: functionSelector,
          value: totalValue,
          maxFeeBp: 0,
          orders: [
            {
              price: priceOne,
              signer: orderOne.orders[0].user,
              collection: BAYC,
              collectionType: 0,
              tokenIds: [tokenIdOne],
              amounts: [1],
              currency: AddressZero,
              startTime: 0,
              endTime: BigNumber.from(orderOne.orders[0].deadline),
              signature: joinSignature(orderOne.orders[0]),
            },
            {
              price: priceTwo,
              signer: orderTwo.orders[0].user,
              collection: BAYC,
              collectionType: 0,
              tokenIds: [tokenIdTwo],
              amounts: [1],
              currency: AddressZero,
              startTime: 0,
              endTime: orderTwo.orders[0].deadline,
              signature: joinSignature(orderTwo.orders[0]),
            },
            {
              price: priceThree,
              signer: orderThree.orders[0].user,
              collection: PARALLEL,
              collectionType: 1,
              tokenIds: [tokenIdThree],
              amounts: [1],
              currency: AddressZero,
              startTime: 0,
              endTime: orderThree.orders[0].deadline,
              signature: joinSignature(orderThree.orders[0]),
            },
            {
              price: priceFour,
              signer: orderFour.orders[0].user,
              collection: PARALLEL,
              collectionType: 1,
              tokenIds: [tokenIdFour],
              amounts: [1],
              currency: AddressZero,
              startTime: 0,
              endTime: orderFour.orders[0].deadline,
              signature: joinSignature(orderFour.orders[0]),
            },
          ],
          ordersExtraData: [
            getX2Y2ExtraData(orderOne),
            getX2Y2ExtraData(orderTwo),
            getX2Y2ExtraData(orderThree),
            getX2Y2ExtraData(orderFour),
          ],
          extraData: HashZero,
        },
      ],
      buyer.address,
      buyer.address,
      false,
      { value: totalValue }
    );
    const receipt = await tx.wait();
    validateSweepEvent(receipt, buyer.address);

    expect(await bayc.balanceOf(buyer.address)).to.equal(2);
    expect(await bayc.ownerOf(tokenIdOne)).to.equal(buyer.address);
    expect(await bayc.ownerOf(tokenIdTwo)).to.equal(buyer.address);

    expect(await parallel.balanceOf(buyer.address, tokenIdThree)).to.equal(1);
    expect(await parallel.balanceOf(buyer.address, tokenIdFour)).to.equal(1);
  });

  // Trying to crash the second trade by buying the same NFT twice, but the first trade should still go through
  // and there should be a refund for the second trade.
  it("Should be able to handle partial trades", async function () {
    const { aggregator, proxy, functionSelector, buyer, bayc } = await loadFixture(deployX2Y2Fixture);

    const { AddressZero, HashZero } = ethers.constants;
    const { getBalance } = ethers.provider;

    // BLOCK 15346990

    const orderOne = getFixture("x2y2", `bayc-${tokenIdOne}-run-input.json`);
    const priceOne = BigNumber.from(orderOne.details[0].price);
    const totalValue = priceOne.add(priceOne);

    const buyerBalanceBefore = await getBalance(buyer.address);

    const orderOneJson = {
      price: priceOne,
      signer: orderOne.orders[0].user,
      collection: BAYC,
      collectionType: 0,
      tokenIds: [tokenIdOne],
      amounts: [1],
      currency: AddressZero,
      startTime: 0,
      endTime: BigNumber.from(orderOne.orders[0].deadline),
      signature: joinSignature(orderOne.orders[0]),
    };

    const tx = await aggregator.connect(buyer).execute(
      [],
      [
        {
          proxy: proxy.address,
          selector: functionSelector,
          value: totalValue,
          maxFeeBp: 0,
          orders: [orderOneJson, orderOneJson],
          ordersExtraData: [getX2Y2ExtraData(orderOne), getX2Y2ExtraData(orderOne)],
          extraData: HashZero,
        },
      ],
      buyer.address,
      buyer.address,
      false,
      { value: totalValue }
    );
    const receipt = await tx.wait();
    const txFee = await calculateTxFee(tx);

    validateSweepEvent(receipt, buyer.address);

    expect(await bayc.balanceOf(buyer.address)).to.equal(1);
    expect(await bayc.ownerOf(tokenIdOne)).to.equal(buyer.address);
    expect(await getBalance(aggregator.address)).to.equal(0);
    expect(await getBalance(proxy.address)).to.equal(0);
    const buyerBalanceAfter = await getBalance(buyer.address);
    expect(buyerBalanceBefore.sub(buyerBalanceAfter).sub(txFee)).to.equal(priceOne);
  });

  it("Should be able to handle atomic trades", async function () {
    const { aggregator, proxy, functionSelector, buyer, bayc } = await loadFixture(deployX2Y2Fixture);

    const { AddressZero, HashZero } = ethers.constants;
    const { getBalance } = ethers.provider;

    // BLOCK 15346990

    const orderOne = getFixture("x2y2", `bayc-${tokenIdOne}-run-input.json`);
    const priceOne = BigNumber.from(orderOne.details[0].price);
    const totalValue = priceOne.add(priceOne);

    const buyerBalanceBefore = await getBalance(buyer.address);

    const orderOneJson = {
      price: priceOne,
      signer: orderOne.orders[0].user,
      collection: BAYC,
      collectionType: 0,
      tokenIds: [tokenIdOne],
      amounts: [1],
      currency: AddressZero,
      startTime: 0,
      endTime: BigNumber.from(orderOne.orders[0].deadline),
      signature: joinSignature(orderOne.orders[0]),
    };

    await expect(
      aggregator.connect(buyer).execute(
        [],
        [
          {
            proxy: proxy.address,
            selector: functionSelector,
            value: totalValue,
            maxFeeBp: 0,
            orders: [orderOneJson, orderOneJson],
            ordersExtraData: [getX2Y2ExtraData(orderOne), getX2Y2ExtraData(orderOne)],
            extraData: HashZero,
          },
        ],
        buyer.address,
        buyer.address,
        true,
        { value: totalValue }
      )
    ).to.be.revertedWith("order already exists");

    expect(await bayc.balanceOf(buyer.address)).to.equal(0);
    expect(await getBalance(aggregator.address)).to.equal(0);
    expect(await getBalance(proxy.address)).to.equal(0);
    const buyerBalanceAfter = await getBalance(buyer.address);
    expect(buyerBalanceBefore.sub(buyerBalanceAfter)).to.be.lt(ethers.utils.parseEther("0.005"));
  });
});
