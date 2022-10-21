import { expect } from "chai";
import { ethers } from "hardhat";
import {
  SEAPORT_CONSIDERATION_FULFILLMENTS_TWO_ORDERS_SAME_COLLECTION,
  SEAPORT_EXTRA_DATA_SCHEMA,
  SEAPORT_OFFER_FULFILLMENT_TWO_ITEMS,
} from "../../constants";
import deploySeaportFixture from "../fixtures/deploy-seaport-fixture";
import calculateTxFee from "../utils/calculate-tx-fee";
import combineConsiderationAmount from "../utils/combine-consideration-amount";
import getFixture from "../utils/get-fixture";
import getSeaportOrderExtraData from "../utils/get-seaport-order-extra-data";
import getSeaportOrderJson from "../utils/get-seaport-order-json";
import validateSweepEvent from "../utils/validate-sweep-event";

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

export default function behavesLikeSeaportERC1155(isAtomic: boolean): void {
  let snapshot: number;

  beforeEach(async () => {
    snapshot = await ethers.provider.send("evm_snapshot", []);
  });

  afterEach(async () => {
    ethers.provider.send("evm_revert", [snapshot]);
  });

  it("Should be able to handle OpenSea trades", async function () {
    const { aggregator, buyer, proxy, functionSelector, cityDao } = await deploySeaportFixture();

    const orders = getFixture("seaport", "city-dao-orders.json");
    const orderOne = orders[0];
    const orderTwo = orders[1];

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
        extraData: isAtomic ? encodedExtraData() : ethers.constants.HashZero,
      },
    ];

    const tx = await aggregator
      .connect(buyer)
      .execute([], tradeData, buyer.address, buyer.address, isAtomic, { value: price });
    const receipt = await tx.wait();

    validateSweepEvent(receipt, buyer.address);

    expect(await cityDao.balanceOf(buyer.address, 42)).to.equal(2);
  });

  it("is able to refund extra ETH paid (not trickled down to SeaportProxy)", async function () {
    const { aggregator, buyer, proxy, functionSelector, cityDao } = await deploySeaportFixture();
    const { getBalance } = ethers.provider;

    const orders = getFixture("seaport", "city-dao-orders.json");
    const orderOne = orders[0];
    const orderTwo = orders[1];

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
        extraData: isAtomic ? encodedExtraData() : ethers.constants.HashZero,
      },
    ];

    const buyerBalanceBefore = await getBalance(buyer.address);

    const tx = await aggregator.connect(buyer).execute([], tradeData, buyer.address, buyer.address, isAtomic, {
      value: price.add(ethers.constants.WeiPerEther),
    });
    const receipt = await tx.wait();
    const txFee = await calculateTxFee(tx);

    validateSweepEvent(receipt, buyer.address);

    expect(await cityDao.balanceOf(buyer.address, 42)).to.equal(2);
    expect(await getBalance(aggregator.address)).to.equal(0);
    const buyerBalanceAfter = await getBalance(buyer.address);
    expect(buyerBalanceBefore.sub(buyerBalanceAfter).sub(txFee)).to.equal(price);
  });

  it("is able to refund extra ETH paid (trickled down to SeaportProxy)", async function () {
    const { aggregator, buyer, proxy, functionSelector, cityDao } = await deploySeaportFixture();
    const { getBalance } = ethers.provider;

    const orders = getFixture("seaport", "city-dao-orders.json");
    const orderOne = orders[0];
    const orderTwo = orders[1];

    const { WeiPerEther } = ethers.constants;
    const priceOne = WeiPerEther;
    const priceTwo = WeiPerEther;
    const price = priceOne.add(priceTwo);

    const tradeData = [
      {
        proxy: proxy.address,
        selector: functionSelector,
        value: price,
        maxFeeBp: 0,
        orders: [getSeaportOrderJson(orderOne), getSeaportOrderJson(orderTwo)],
        ordersExtraData: [getSeaportOrderExtraData(orderOne), getSeaportOrderExtraData(orderTwo)],
        extraData: isAtomic ? encodedExtraData() : ethers.constants.HashZero,
      },
    ];

    const buyerBalanceBefore = await getBalance(buyer.address);

    const tx = await aggregator
      .connect(buyer)
      .execute([], tradeData, buyer.address, buyer.address, isAtomic, { value: price });
    const receipt = await tx.wait();
    const txFee = await calculateTxFee(tx);

    validateSweepEvent(receipt, buyer.address);

    expect(await cityDao.balanceOf(buyer.address, 42)).to.equal(2);
    expect(await getBalance(aggregator.address)).to.equal(0);
    const buyerBalanceAfter = await getBalance(buyer.address);
    const actualPriceOne = combineConsiderationAmount(orderOne.parameters.consideration);
    const actualPriceTwo = combineConsiderationAmount(orderTwo.parameters.consideration);
    expect(buyerBalanceBefore.sub(buyerBalanceAfter).sub(txFee)).to.equal(actualPriceOne.add(actualPriceTwo));
  });
}
