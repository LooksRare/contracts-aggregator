import { expect } from "chai";
import { ethers } from "hardhat";
import {
  BAYC,
  LOOKSRARE_EXTRA_DATA_SCHEMA,
  LOOKSRARE_STRATEGY_FIXED_PRICE,
  SEAPORT_CONSIDERATION_FULFILLMENTS_ONE_ORDER,
  SEAPORT_EXTRA_DATA_SCHEMA,
  SEAPORT_OFFER_FULFILLMENT_ONE_ITEM,
  WETH,
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
  it("Should be able to handle conflicted orders", async function () {
    const { getBalance } = ethers.provider;
    const tokenId = 9314;
    const {
      aggregator,
      buyer,
      looksRareProxy,
      looksRareFunctionSelector,
      seaportProxy,
      seaportFunctionSelector,
      bayc,
    } = await loadFixture(deployMultipleMarketFixtures);

    const seaportOrder = getFixture("seaport", "bayc-9314-order.json");

    const seaportPrice = combineConsiderationAmount(seaportOrder.parameters.consideration);
    const looksRarePrice = ethers.utils.parseEther("87.95");
    const price = seaportPrice.add(looksRarePrice);

    const abiCoder = ethers.utils.defaultAbiCoder;
    const tradeData = [
      {
        proxy: seaportProxy.address,
        selector: seaportFunctionSelector,
        value: seaportPrice,
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
        orders: [
          {
            signer: "0x3445A938F98EaAeb6AF3ce90e71FC5994a23F897",
            collection: BAYC,
            collectionType: 0,
            tokenIds: [tokenId],
            amounts: [1],
            price: looksRarePrice,
            currency: WETH,
            startTime: 1659415937,
            endTime: 1661764279,
            signature:
              "0x0ad409048cbf4b75ab2dec2cdb7f57b6e0b1a3490a9230d8146f1eec9185ae1078735b237ff2088320f00204968b1eb396d374dfba9fbc79dedde4a53670f8b000",
          },
        ],
        ordersExtraData: [
          abiCoder.encode(LOOKSRARE_EXTRA_DATA_SCHEMA, [looksRarePrice, 9550, 2, LOOKSRARE_STRATEGY_FIXED_PRICE]),
        ],
        extraData: ethers.constants.HashZero,
      },
    ];

    const buyerBalanceBefore = await getBalance(buyer.address);

    const tx = await aggregator.connect(buyer).execute([], tradeData, buyer.address, false, { value: price });
    const receipt = await tx.wait();
    const txFee = await calculateTxFee(tx);

    validateSweepEvent(receipt, buyer.address, 2, 1);

    expect(await bayc.balanceOf(buyer.address)).to.equal(1);
    expect(await bayc.ownerOf(tokenId)).to.equal(buyer.address);

    expect(await getBalance(aggregator.address)).to.equal(0);
    const buyerBalanceAfter = await getBalance(buyer.address);
    expect(buyerBalanceBefore.sub(buyerBalanceAfter).sub(txFee)).to.equal(seaportPrice);
  });

  it("Reverts with the swaps have to be atomic", async function () {
    const { getBalance } = ethers.provider;
    const tokenId = 9314;
    const {
      aggregator,
      buyer,
      looksRareProxy,
      looksRareFunctionSelector,
      seaportProxy,
      seaportFunctionSelector,
      bayc,
    } = await loadFixture(deployMultipleMarketFixtures);

    const seaportOrder = getFixture("seaport", "bayc-9314-order.json");

    const seaportPrice = combineConsiderationAmount(seaportOrder.parameters.consideration);
    const looksRarePrice = ethers.utils.parseEther("87.95");
    const price = seaportPrice.add(looksRarePrice);

    const abiCoder = ethers.utils.defaultAbiCoder;
    const tradeData = [
      {
        proxy: seaportProxy.address,
        selector: seaportFunctionSelector,
        value: seaportPrice,
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
        orders: [
          {
            signer: "0x3445A938F98EaAeb6AF3ce90e71FC5994a23F897",
            collection: BAYC,
            collectionType: 0,
            tokenIds: [tokenId],
            amounts: [1],
            price: looksRarePrice,
            currency: WETH,
            startTime: 1659415937,
            endTime: 1661764279,
            signature:
              "0x0ad409048cbf4b75ab2dec2cdb7f57b6e0b1a3490a9230d8146f1eec9185ae1078735b237ff2088320f00204968b1eb396d374dfba9fbc79dedde4a53670f8b000",
          },
        ],
        ordersExtraData: [
          abiCoder.encode(LOOKSRARE_EXTRA_DATA_SCHEMA, [looksRarePrice, 9550, 2, LOOKSRARE_STRATEGY_FIXED_PRICE]),
        ],
        extraData: ethers.constants.HashZero,
      },
    ];

    const buyerBalanceBefore = await ethers.provider.getBalance(buyer.address);

    await expect(
      aggregator.connect(buyer).execute([], tradeData, buyer.address, true, { value: price })
    ).to.be.revertedWith("BadSignatureV(0)");

    expect(await bayc.balanceOf(buyer.address)).to.equal(0);

    expect(await getBalance(aggregator.address)).to.equal(0);
    expect(await getBalance(seaportProxy.address)).to.equal(0);
    expect(await getBalance(looksRareProxy.address)).to.equal(0);

    const buyerBalanceAfter = await getBalance(buyer.address);
    // Just need to get a rough estimate on the tx fee as we don't have the tx receipt
    expect(buyerBalanceBefore.sub(buyerBalanceAfter)).to.be.lt(ethers.utils.parseEther("0.005"));
  });
});
