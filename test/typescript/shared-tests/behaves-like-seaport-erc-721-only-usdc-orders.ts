import { ethers } from "hardhat";
import getFixture from "../utils/get-fixture";
import deploySeaportFixture from "../fixtures/deploy-seaport-fixture";
import combineConsiderationAmount from "../utils/combine-consideration-amount";
import getSeaportOrderJson from "../utils/get-seaport-order-json";
import getSeaportOrderExtraData from "../utils/get-seaport-order-extra-data";
import {
  SEAPORT_EXTRA_DATA_SCHEMA,
  SEAPORT_OFFER_FULFILLMENT_TWO_ITEMS,
  SEAPORT_CONSIDERATION_FULFILLMENTS_TWO_ORDERS_SAME_COLLECTION,
  USDC,
  SEAPORT,
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
        considerationFulfillments: SEAPORT_CONSIDERATION_FULFILLMENTS_TWO_ORDERS_SAME_COLLECTION,
      },
    ]
  );
};

export default function behavesLikeSeaportERC721OnlyUSDCOrders(isAtomic: boolean): void {
  it("Should be able to charge a fee", async function () {
    const { aggregator, buyer, proxy, functionSelector, bayc } = await loadFixture(deploySeaportFixture);

    const [, protocolFeeRecipient] = await ethers.getSigners();

    const orderOne = getFixture("seaport", "bayc-9948-order.json");
    const orderTwo = getFixture("seaport", "bayc-8350-order.json");

    const priceOneBeforeFee = combineConsiderationAmount(orderOne.parameters.consideration);
    const priceOne = priceOneBeforeFee.mul(10250).div(10000); // Fee
    const priceTwoBeforeFee = combineConsiderationAmount(orderTwo.parameters.consideration);
    const priceTwo = priceTwoBeforeFee.mul(10250).div(10000); // Fee
    const price = priceOne.add(priceTwo);

    await aggregator.approve(SEAPORT, USDC);
    await proxy.setFeeBp(250);
    await proxy.setFeeRecipient(protocolFeeRecipient.address);

    await airdropUSDC(buyer.address, price);

    const usdc = await ethers.getContractAt("IERC20", USDC);
    await usdc.connect(buyer).approve(aggregator.address, price);

    const tokenTransfers = [{ amount: price, currency: USDC }];

    const tradeData = [
      {
        proxy: proxy.address,
        selector: functionSelector,
        value: 0,
        orders: [getSeaportOrderJson(orderOne), getSeaportOrderJson(orderTwo)],
        ordersExtraData: [getSeaportOrderExtraData(orderOne), getSeaportOrderExtraData(orderTwo)],
        extraData: isAtomic ? encodedExtraData() : ethers.constants.HashZero,
        tokenTransfers,
      },
    ];

    const feeRecipientUSDCBalanceBefore = await usdc.balanceOf(protocolFeeRecipient.address);

    const tx = await aggregator
      .connect(buyer)
      .execute(tokenTransfers, tradeData, buyer.address, isAtomic, { value: price });
    const receipt = await tx.wait();

    const feeRecipientUSDCBalanceAfter = await usdc.balanceOf(protocolFeeRecipient.address);
    expect(feeRecipientUSDCBalanceAfter.sub(feeRecipientUSDCBalanceBefore)).to.equal(
      priceOne.sub(priceOneBeforeFee).add(priceTwo.sub(priceTwoBeforeFee))
    );

    validateSweepEvent(receipt, buyer.address, 1, 1);

    expect(await bayc.balanceOf(buyer.address)).to.equal(2);
    expect(await bayc.ownerOf(9948)).to.equal(buyer.address);
    expect(await bayc.ownerOf(8350)).to.equal(buyer.address);
  });
}
