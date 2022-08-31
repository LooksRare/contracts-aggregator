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
  it("Should be able to handle trades from multiple markets", async function () {
    const { AddressZero, HashZero } = ethers.constants;
    const {
      aggregator,
      buyer,
      looksRareProxy,
      looksRareFunctionSelector,
      seaportProxy,
      seaportFunctionSelector,
      sudoswapProxy,
      sudoswapFunctionSelector,
      bayc,
    } = await loadFixture(deployMultipleMarketFixtures);
    const sudoswapPair = await ethers.getContractAt("ISudoswapPair", "0xc44b755cb278b682de1Cb07c7B3D15C44be62c34");
    const sudoswapQuote = await sudoswapPair.getBuyNFTQuote(1);

    const seaportOrder = getFixture("seaport", "bayc-6092-order.json");

    const seaportPrice = combineConsiderationAmount(seaportOrder.parameters.consideration);
    const looksRarePrice = ethers.utils.parseEther("78.69");
    const sudoswapPrice = sudoswapQuote[3];
    const price = seaportPrice.add(looksRarePrice).add(sudoswapPrice);

    const abiCoder = ethers.utils.defaultAbiCoder;
    const tradeData = [
      {
        proxy: seaportProxy.address,
        selector: seaportFunctionSelector,
        value: seaportPrice,
        orders: [getSeaportOrderJson(seaportOrder, seaportPrice)],
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
        tokenTransfers: [],
      },
      {
        proxy: looksRareProxy.address,
        selector: looksRareFunctionSelector,
        value: looksRarePrice,
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
        tokenTransfers: [],
      },
      {
        proxy: sudoswapProxy.address,
        selector: sudoswapFunctionSelector,
        value: sudoswapPrice,
        orders: [
          {
            signer: AddressZero,
            collection: "0xc44b755cb278b682de1Cb07c7B3D15C44be62c34",
            collectionType: 0,
            tokenIds: [8167],
            amounts: [1],
            price: sudoswapPrice,
            currency: AddressZero,
            startTime: 0,
            endTime: 0,
            signature: HashZero,
          },
        ],
        ordersExtraData: [HashZero, HashZero],
        extraData: HashZero,
        tokenTransfers: [],
      },
    ];

    const tx = await aggregator.connect(buyer).execute(tradeData, buyer.address, false, { value: price });
    const receipt = await tx.wait();
    validateSweepEvent(receipt, buyer.address, 3, 3);

    expect(await bayc.balanceOf(buyer.address)).to.equal(3);
    expect(await bayc.ownerOf(6092)).to.equal(buyer.address);
    expect(await bayc.ownerOf(2491)).to.equal(buyer.address);
    expect(await bayc.ownerOf(8167)).to.equal(buyer.address);
  });

  it("Should be able to handle partial trades", async function () {
    const { AddressZero, HashZero } = ethers.constants;
    const { getBalance } = ethers.provider;
    const {
      aggregator,
      buyer,
      looksRareProxy,
      looksRareFunctionSelector,
      seaportProxy,
      seaportFunctionSelector,
      sudoswapProxy,
      sudoswapFunctionSelector,
      bayc,
    } = await loadFixture(deployMultipleMarketFixtures);
    const sudoswapPair = await ethers.getContractAt("ISudoswapPair", "0xc44b755cb278b682de1Cb07c7B3D15C44be62c34");
    const sudoswapQuote = await sudoswapPair.getBuyNFTQuote(1);

    const seaportOrder = getFixture("seaport", "bayc-6092-order.json");

    const seaportPrice = combineConsiderationAmount(seaportOrder.parameters.consideration);
    const looksRarePrice = ethers.utils.parseEther("78.69");
    const sudoswapPrice = sudoswapQuote[3];
    const price = seaportPrice.add(looksRarePrice).add(sudoswapPrice);

    const abiCoder = ethers.utils.defaultAbiCoder;
    let tradeData = [
      {
        proxy: seaportProxy.address,
        selector: seaportFunctionSelector,
        value: seaportPrice,
        orders: [getSeaportOrderJson(seaportOrder, seaportPrice)],
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
        tokenTransfers: [],
      },
      {
        proxy: looksRareProxy.address,
        selector: looksRareFunctionSelector,
        value: looksRarePrice,
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
        extraData: HashZero,
        tokenTransfers: [],
      },
      {
        proxy: sudoswapProxy.address,
        selector: sudoswapFunctionSelector,
        value: sudoswapPrice,
        orders: [
          {
            signer: AddressZero,
            collection: "0xc44b755cb278b682de1Cb07c7B3D15C44be62c34",
            collectionType: 0,
            tokenIds: [8167],
            amounts: [1],
            price: sudoswapPrice,
            currency: AddressZero,
            startTime: 0,
            endTime: 0,
            signature: HashZero,
          },
        ],
        ordersExtraData: [HashZero, HashZero],
        extraData: HashZero,
        tokenTransfers: [],
      },
    ];
    // Duplicating the orders to make the 2nd batch fail
    tradeData = tradeData.concat(tradeData);

    const buyerBalanceBefore = await getBalance(buyer.address);

    const tx = await aggregator.connect(buyer).execute(tradeData, buyer.address, false, { value: price.mul(2) });
    const receipt = await tx.wait();
    const txFee = await calculateTxFee(tx);

    validateSweepEvent(receipt, buyer.address, 6, 3);

    expect(await bayc.balanceOf(buyer.address)).to.equal(3);
    expect(await bayc.ownerOf(6092)).to.equal(buyer.address);
    expect(await bayc.ownerOf(2491)).to.equal(buyer.address);
    expect(await bayc.ownerOf(8167)).to.equal(buyer.address);

    expect(await getBalance(aggregator.address)).to.equal(0);
    expect(await getBalance(looksRareProxy.address)).to.equal(0);
    expect(await getBalance(seaportProxy.address)).to.equal(0);
    expect(await getBalance(sudoswapProxy.address)).to.equal(0);
    const buyerBalanceAfter = await getBalance(buyer.address);
    expect(buyerBalanceBefore.sub(buyerBalanceAfter).sub(txFee)).to.equal(price);
  });

  it("Should be able to handle atomic trades", async function () {
    const { AddressZero, HashZero } = ethers.constants;
    const { getBalance } = ethers.provider;
    const {
      aggregator,
      buyer,
      looksRareProxy,
      looksRareFunctionSelector,
      seaportProxy,
      seaportFunctionSelector,
      sudoswapProxy,
      sudoswapFunctionSelector,
      bayc,
    } = await loadFixture(deployMultipleMarketFixtures);
    const sudoswapPair = await ethers.getContractAt("ISudoswapPair", "0xc44b755cb278b682de1Cb07c7B3D15C44be62c34");
    const sudoswapQuote = await sudoswapPair.getBuyNFTQuote(1);

    const seaportOrder = getFixture("seaport", "bayc-6092-order.json");

    const seaportPrice = combineConsiderationAmount(seaportOrder.parameters.consideration);
    const looksRarePrice = ethers.utils.parseEther("78.69");
    const sudoswapPrice = sudoswapQuote[3];
    const price = seaportPrice.add(looksRarePrice).add(sudoswapPrice);

    const abiCoder = ethers.utils.defaultAbiCoder;
    let tradeData = [
      {
        proxy: seaportProxy.address,
        selector: seaportFunctionSelector,
        value: seaportPrice,
        orders: [getSeaportOrderJson(seaportOrder, seaportPrice)],
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
        tokenTransfers: [],
      },
      {
        proxy: looksRareProxy.address,
        selector: looksRareFunctionSelector,
        value: looksRarePrice,
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
        tokenTransfers: [],
      },
      {
        proxy: sudoswapProxy.address,
        selector: sudoswapFunctionSelector,
        value: sudoswapPrice,
        orders: [
          {
            signer: AddressZero,
            collection: "0xc44b755cb278b682de1Cb07c7B3D15C44be62c34",
            collectionType: 0,
            tokenIds: [8167],
            amounts: [1],
            price: sudoswapPrice,
            currency: AddressZero,
            startTime: 0,
            endTime: 0,
            signature: HashZero,
          },
        ],
        ordersExtraData: [HashZero, HashZero],
        extraData: HashZero,
        tokenTransfers: [],
      },
    ];
    // Duplicating the orders to make the 2nd batch fail
    tradeData = tradeData.concat(tradeData);

    const buyerBalanceBefore = await getBalance(buyer.address);

    await expect(aggregator.connect(buyer).execute(tradeData, buyer.address, true, { value: price.mul(2) })).to.be
      .reverted;

    expect(await bayc.balanceOf(buyer.address)).to.equal(0);

    expect(await getBalance(aggregator.address)).to.equal(0);
    expect(await getBalance(looksRareProxy.address)).to.equal(0);
    expect(await getBalance(seaportProxy.address)).to.equal(0);
    expect(await getBalance(sudoswapProxy.address)).to.equal(0);
    const buyerBalanceAfter = await getBalance(buyer.address);
    expect(buyerBalanceBefore.sub(buyerBalanceAfter)).to.be.lt(ethers.utils.parseEther("0.01"));
  });
});
