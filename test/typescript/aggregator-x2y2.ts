import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import deployX2Y2Fixture from "./fixtures/deploy-x2y2-fixture";
import { BAYC, PARALLEL, X2Y2_ORDER_EXTRA_DATA_SCHEMA } from "../constants";
import { BigNumber } from "ethers";
import { expect } from "chai";
import getFixture from "./utils/get-fixture";

describe("LooksRareAggregator", () => {
  const joinSignature = (order: any): string => {
    return ethers.utils.joinSignature({
      r: order.r,
      s: order.s,
      recoveryParam: order.v === 28 ? 1 : 0,
      v: order.v,
    });
  };

  interface Fee {
    percentage: BigNumber;
    to: string;
  }

  const getX2Y2ExtraData = (order: any): string => {
    const abiCoder = ethers.utils.defaultAbiCoder;
    return abiCoder.encode(
      [X2Y2_ORDER_EXTRA_DATA_SCHEMA],
      [
        {
          salt: BigNumber.from(order.orders[0].salt),
          itemData: order.orders[0].items[0].data,
          executionDelegate: order.details[0].executionDelegate,
          inputSalt: BigNumber.from(order.shared.salt),
          inputDeadline: BigNumber.from(order.shared.deadline),
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

  it("Should be able to handle X2Y2 trades", async function () {
    const { aggregator, proxy, functionSelector, buyer, bayc, parallel } = await loadFixture(deployX2Y2Fixture);

    const { AddressZero } = ethers.constants;

    // BLOCK 15346990

    const tokenIdOne = "2674";
    const tokenIdTwo = "2491";
    const tokenIdThree = "10327";
    const tokenIdFour = "10511";

    const orderOne = getFixture("x2y2", `bayc-${tokenIdOne}-run-input.json`);
    const orderTwo = getFixture("x2y2", `bayc-${tokenIdTwo}-run-input.json`);
    const orderThree = getFixture("x2y2", `parallel-${tokenIdThree}-run-input.json`);
    const orderFour = getFixture("x2y2", `parallel-${tokenIdFour}-run-input.json`);

    const priceOne = BigNumber.from(orderOne.details[0].price);
    const priceTwo = BigNumber.from(orderTwo.details[0].price);
    const priceThree = BigNumber.from(orderThree.details[0].price);
    const priceFour = BigNumber.from(orderFour.details[0].price);

    const totalValue = priceOne.add(priceTwo).add(priceThree).add(priceFour);

    await aggregator.buyWithETH(
      [
        {
          proxy: proxy.address,
          selector: functionSelector,
          value: totalValue,
          orders: [
            {
              price: priceOne,
              recipient: buyer.address,
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
              recipient: buyer.address,
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
              recipient: buyer.address,
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
              recipient: buyer.address,
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
          extraData: ethers.constants.HashZero,
        },
      ],
      { value: totalValue }
    );

    expect(await bayc.balanceOf(buyer.address)).to.equal(2);
    expect(await bayc.ownerOf(tokenIdOne)).to.equal(buyer.address);
    expect(await bayc.ownerOf(tokenIdTwo)).to.equal(buyer.address);

    expect(await parallel.balanceOf(buyer.address, tokenIdThree)).to.equal(1);
    expect(await parallel.balanceOf(buyer.address, tokenIdFour)).to.equal(1);
  });
});
