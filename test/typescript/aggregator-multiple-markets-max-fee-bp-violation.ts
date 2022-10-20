import { expect } from "chai";
import { ethers } from "hardhat";
import {
  BAYC,
  LOOKSRARE_EXTRA_DATA_SCHEMA,
  LOOKSRARE_STRATEGY_FIXED_PRICE,
  SEAPORT_EXTRA_DATA_SCHEMA,
  SEAPORT_CONSIDERATION_FULFILLMENTS_ONE_ORDER,
  WETH,
  SEAPORT_OFFER_FULFILLMENT_ONE_ITEM,
  LOOKSRARE_PROTOCOL_FEE_RECIPIENT,
} from "../constants";
import getFixture from "./utils/get-fixture";
import getSeaportOrderExtraData from "./utils/get-seaport-order-extra-data";
import getSeaportOrderJson from "./utils/get-seaport-order-json";
import combineConsiderationAmount from "./utils/combine-consideration-amount";

import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import deployMultipleMarketFixtures from "./fixtures/deploy-multiple-markets-fixture";
import calculateTxFee from "./utils/calculate-tx-fee";
import validateSweepEvent from "./utils/validate-sweep-event";

describe("Aggregator", () => {
  const setUp = async () => {
    const {
      aggregator,
      bayc,
      buyer,
      looksRareProxy,
      looksRareFunctionSelector,
      seaportProxy,
      seaportFunctionSelector,
    } = await loadFixture(deployMultipleMarketFixtures);

    await aggregator.setFee(seaportProxy.address, 250, LOOKSRARE_PROTOCOL_FEE_RECIPIENT);

    const seaportOrder = getFixture("seaport", "bayc-6092-order.json");

    const seaportPrice = combineConsiderationAmount(seaportOrder.parameters.consideration);
    const looksRarePrice = ethers.utils.parseEther("78.69");
    const price = seaportPrice.add(looksRarePrice);

    const abiCoder = ethers.utils.defaultAbiCoder;
    const tradeData = [
      {
        proxy: seaportProxy.address,
        selector: seaportFunctionSelector,
        value: seaportPrice.mul(10249).div(10000),
        maxFeeBp: 249,
        orders: [getSeaportOrderJson(seaportOrder)],
        ordersExtraData: [getSeaportOrderExtraData(seaportOrder)],
        extraData: abiCoder.encode(
          [SEAPORT_EXTRA_DATA_SCHEMA],
          [
            {
              offerFulfillments: SEAPORT_OFFER_FULFILLMENT_ONE_ITEM,
              considerationFulfillments: SEAPORT_CONSIDERATION_FULFILLMENTS_ONE_ORDER,
            },
          ]
        ),
      },
      {
        proxy: looksRareProxy.address,
        selector: looksRareFunctionSelector,
        value: looksRarePrice,
        maxFeeBp: 0,
        orders: [
          {
            signer: "0xCd46DEe6e832e3ffa3FdC394b8dC673D6CA843dd",
            collection: BAYC,
            collectionType: 0,
            tokenIds: [2491],
            amounts: [1],
            price: looksRarePrice,
            currency: WETH,
            startTime: 1660231310,
            endTime: 1668007269,
            signature:
              "0x7b37474f79837ee4e56faf1e766a30a9d9c6ed3a7984457bcb212381f2b6b8f95a641ec95eca31f060a15a3c9ff2d4fbccbf481c766e8630be72b6e3e3aeca561b",
          },
        ],
        ordersExtraData: [
          abiCoder.encode(LOOKSRARE_EXTRA_DATA_SCHEMA, [looksRarePrice, 9550, 0, LOOKSRARE_STRATEGY_FIXED_PRICE]),
        ],
        extraData: ethers.constants.HashZero,
      },
    ];

    return { aggregator, bayc, buyer, looksRarePrice, looksRareProxy, price, seaportProxy, tradeData };
  };

  it("Should revert if the trade is atomic and max fee bp is violated", async function () {
    const { aggregator, buyer, price, tradeData } = await setUp();
    await expect(
      aggregator.connect(buyer).execute([], tradeData, buyer.address, buyer.address, true, { value: price })
    ).to.be.revertedWith("FeeTooHigh");
  });

  it("Should skip max fee bp violated trades if the trade is non-atomic", async function () {
    const { aggregator, buyer, looksRarePrice, looksRareProxy, price, seaportProxy, tradeData, bayc } = await setUp();

    const { getBalance } = ethers.provider;
    const buyerBalanceBefore = await getBalance(buyer.address);

    const tx = await aggregator
      .connect(buyer)
      .execute([], tradeData, buyer.address, buyer.address, false, { value: price });
    const txFee = await calculateTxFee(tx);
    const receipt = await tx.wait();
    validateSweepEvent(receipt, buyer.address);

    expect(await bayc.balanceOf(buyer.address)).to.equal(1);
    expect(await bayc.ownerOf(6092)).to.not.equal(buyer.address);
    expect(await bayc.ownerOf(2491)).to.equal(buyer.address);

    expect(await getBalance(aggregator.address)).to.equal(0);
    expect(await getBalance(looksRareProxy.address)).to.equal(0);
    expect(await getBalance(seaportProxy.address)).to.equal(0);
    const buyerBalanceAfter = await getBalance(buyer.address);
    expect(buyerBalanceBefore.sub(buyerBalanceAfter).sub(txFee)).to.equal(looksRarePrice);
  });
});