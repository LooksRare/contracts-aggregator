import { expect } from "chai";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import { SEAPORT_EXTRA_DATA_SCHEMA, SEAPORT_ORDER_EXTRA_DATA_SCHEMA } from "../constants";
import getFixture from "./utils/get-fixture";
import calculateTxFee from "./utils/calculate-tx-fee";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import deploySeaportFixture from "./fixtures/deploy-seaport-fixture";

describe("Aggregator", () => {
  const offerFulfillments = [[{ orderIndex: 0, itemIndex: 0 }], [{ orderIndex: 1, itemIndex: 0 }]];

  const considerationFulfillments = [
    // seller one
    [{ orderIndex: 0, itemIndex: 0 }],
    // seller two
    [{ orderIndex: 1, itemIndex: 0 }],
    // OpenSea: Fees
    [
      { orderIndex: 0, itemIndex: 1 },
      { orderIndex: 1, itemIndex: 1 },
    ],
    // royalty
    [
      { orderIndex: 0, itemIndex: 2 },
      { orderIndex: 1, itemIndex: 2 },
    ],
  ];

  const combineConsiderationAmount = (consideration: Array<any>) =>
    consideration.reduce((sum: number, item: any) => BigNumber.from(item.endAmount).add(sum), 0);

  const getOrderJson = (listing: any, price: BigNumber, recipient: string) => {
    const order = {
      price,
      recipient,
      signer: listing.parameters.offerer,
      collection: listing.parameters.offer[0].token,
      collectionType: 0,
      tokenIds: [listing.parameters.offer[0].identifierOrCriteria],
      amounts: [1],
      currency: listing.parameters.consideration[0].token,
      startTime: listing.parameters.startTime,
      endTime: listing.parameters.endTime,
      signature: listing.signature,
    };

    return order;
  };

  const getOrderExtraData = (order: any): string => {
    const abiCoder = ethers.utils.defaultAbiCoder;
    return abiCoder.encode(
      [SEAPORT_ORDER_EXTRA_DATA_SCHEMA],
      [
        {
          orderType: order.parameters.orderType,
          zone: order.parameters.zone,
          zoneHash: order.parameters.zoneHash,
          salt: order.parameters.salt,
          conduitKey: order.parameters.conduitKey,
          recipients: order.parameters.consideration.map((item: any) => ({
            recipient: item.recipient,
            amount: item.endAmount,
          })),
        },
      ]
    );
  };

  it("Should be able to handle OpenSea trades (fulfillAvailableAdvancedOrders)", async function () {
    const { aggregator, buyer, proxy, functionSelector, bayc } = await loadFixture(deploySeaportFixture);

    const orderOne = getFixture("bayc-2518-order.json");
    const orderTwo = getFixture("bayc-8498-order.json");

    const priceOne = combineConsiderationAmount(orderOne.parameters.consideration);
    const priceTwo = combineConsiderationAmount(orderTwo.parameters.consideration);
    const price = priceOne.add(priceTwo);

    const abiCoder = ethers.utils.defaultAbiCoder;
    const tradeData = [
      {
        proxy: proxy.address,
        selector: functionSelector,
        value: price,
        orders: [getOrderJson(orderOne, priceOne, buyer.address), getOrderJson(orderTwo, priceTwo, buyer.address)],
        ordersExtraData: [getOrderExtraData(orderOne), getOrderExtraData(orderTwo)],
        extraData: abiCoder.encode([SEAPORT_EXTRA_DATA_SCHEMA], [{ offerFulfillments, considerationFulfillments }]),
      },
    ];

    const tx = await aggregator
      .connect(buyer)
      .buyWithETH(tradeData, { value: price.add(ethers.utils.parseEther("1")) });
    await tx.wait();

    expect(await bayc.balanceOf(buyer.address)).to.equal(2);
    expect(await bayc.ownerOf(2518)).to.equal(buyer.address);
    expect(await bayc.ownerOf(8498)).to.equal(buyer.address);
  });

  it("is able to refund extra ETH paid (not trickled down to SeaportProxy)", async function () {
    const { aggregator, buyer, proxy, functionSelector, bayc } = await loadFixture(deploySeaportFixture);

    const orderOne = getFixture("bayc-2518-order.json");
    const orderTwo = getFixture("bayc-8498-order.json");

    const priceOne = combineConsiderationAmount(orderOne.parameters.consideration);
    const priceTwo = combineConsiderationAmount(orderTwo.parameters.consideration);
    const price = priceOne.add(priceTwo);

    const abiCoder = ethers.utils.defaultAbiCoder;
    const tradeData = [
      {
        proxy: proxy.address,
        selector: functionSelector,
        value: price,
        orders: [getOrderJson(orderOne, priceOne, buyer.address), getOrderJson(orderTwo, priceTwo, buyer.address)],
        ordersExtraData: [getOrderExtraData(orderOne), getOrderExtraData(orderTwo)],
        extraData: abiCoder.encode([SEAPORT_EXTRA_DATA_SCHEMA], [{ offerFulfillments, considerationFulfillments }]),
      },
    ];

    const buyerBalanceBefore = await ethers.provider.getBalance(buyer.address);

    const tx = await aggregator
      .connect(buyer)
      .buyWithETH(tradeData, { value: price.add(ethers.constants.WeiPerEther) });
    await tx.wait();
    const txFee = await calculateTxFee(tx);

    expect(await bayc.balanceOf(buyer.address)).to.equal(2);
    expect(await bayc.ownerOf(2518)).to.equal(buyer.address);
    expect(await bayc.ownerOf(8498)).to.equal(buyer.address);
    expect(await ethers.provider.getBalance(aggregator.address)).to.equal(0);
    const buyerBalanceAfter = await ethers.provider.getBalance(buyer.address);
    expect(buyerBalanceBefore.sub(buyerBalanceAfter).sub(txFee)).to.equal(price);
  });

  it("is able to refund extra ETH paid (trickled down to SeaportProxy)", async function () {
    const { aggregator, buyer, proxy, functionSelector, bayc } = await loadFixture(deploySeaportFixture);

    const orderOne = getFixture("bayc-2518-order.json");
    const orderTwo = getFixture("bayc-8498-order.json");

    // ~15 ETH higher than the actual price.
    const priceOne = ethers.utils.parseEther("99");
    const priceTwo = ethers.utils.parseEther("99");
    const price = priceOne.add(priceTwo);

    const abiCoder = ethers.utils.defaultAbiCoder;
    const tradeData = [
      {
        proxy: proxy.address,
        selector: functionSelector,
        value: price,
        orders: [getOrderJson(orderOne, priceOne, buyer.address), getOrderJson(orderTwo, priceTwo, buyer.address)],
        ordersExtraData: [getOrderExtraData(orderOne), getOrderExtraData(orderTwo)],
        extraData: abiCoder.encode([SEAPORT_EXTRA_DATA_SCHEMA], [{ offerFulfillments, considerationFulfillments }]),
      },
    ];

    const buyerBalanceBefore = await ethers.provider.getBalance(buyer.address);

    const tx = await aggregator.connect(buyer).buyWithETH(tradeData, { value: price });
    await tx.wait();
    const txFee = await calculateTxFee(tx);

    expect(await bayc.balanceOf(buyer.address)).to.equal(2);
    expect(await bayc.ownerOf(2518)).to.equal(buyer.address);
    expect(await bayc.ownerOf(8498)).to.equal(buyer.address);
    expect(await ethers.provider.getBalance(aggregator.address)).to.equal(0);
    const buyerBalanceAfter = await ethers.provider.getBalance(buyer.address);
    const actualPriceOne = combineConsiderationAmount(orderOne.parameters.consideration);
    const actualPriceTwo = combineConsiderationAmount(orderTwo.parameters.consideration);
    expect(buyerBalanceBefore.sub(buyerBalanceAfter).sub(txFee)).to.equal(actualPriceOne.add(actualPriceTwo));
  });
});