import { expect } from "chai";
import { ethers } from "hardhat";
import { BAYC, LOOKSRARE_EXTRA_DATA_SCHEMA, LOOKSRARE_STRATEGY_FIXED_PRICE, WETH } from "../constants";
import calculateTxFee from "./utils/calculate-tx-fee";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import deployLooksRareFixture from "./fixtures/deploy-looksrare-fixture";
import validateSweepEvent from "./utils/validate-sweep-event";

describe("LooksRareAggregator", () => {
  const tokenIdOne = 7139;
  const tokenIdTwo = 3939;

  before(async () => {
    await ethers.provider.send("hardhat_reset", [
      {
        forking: {
          jsonRpcUrl: process.env.ETH_RPC_URL,
          blockNumber: 15282897,
        },
      },
    ]);
  });

  it("Should be able to handle LooksRare V2 trades (matchAskWithTakerBidUsingETHAndWETH)", async function () {
    const { aggregator, proxy, functionSelector, buyer, bayc } = await loadFixture(deployLooksRareFixture);

    const abiCoder = ethers.utils.defaultAbiCoder;

    const priceOne = ethers.utils.parseEther("81.8");
    const priceTwo = ethers.utils.parseEther("83.391");
    const totalValue = priceOne.add(priceTwo);

    const tradeData = [
      {
        proxy: proxy.address,
        selector: functionSelector,
        value: totalValue,
        maxFeeBp: 0,
        orders: [
          {
            signer: "0x2137213d50207Edfd92bCf4CF7eF9E491A155357",
            collection: BAYC,
            collectionType: 0,
            tokenIds: [tokenIdOne],
            amounts: [1],
            price: priceOne,
            currency: WETH,
            startTime: 1659632508,
            endTime: 1662186976,
            signature:
              "0xe669f75ee8768c3dc4a7ac11f2d301f9dbfced5c1f3c13c7f445ad84d326db4b0f2da0827bac814c4ed782b661ef40dcb2fa71141ef8239a5e5f1038e117549c1c",
          },
          {
            signer: "0xaf0f4479aF9Df756b9b2c69B463214B9a3346443",
            collection: BAYC,
            collectionType: 0,
            tokenIds: [tokenIdTwo],
            amounts: [1],
            price: priceTwo,
            currency: WETH,
            startTime: 1659484473,
            endTime: 1660089268,
            signature:
              "0x146a8f500fea9cde68c339da9abe8654ffb60c5a80506532e3500d1edba687640519093ff36ab3a728c961fc763d6e6a107ed823cfa5bd45182cab8029dab5d21b",
          },
        ],
        ordersExtraData: [
          abiCoder.encode(LOOKSRARE_EXTRA_DATA_SCHEMA, [priceOne, 9550, 0, LOOKSRARE_STRATEGY_FIXED_PRICE]),
          abiCoder.encode(LOOKSRARE_EXTRA_DATA_SCHEMA, [priceTwo, 8500, 50, LOOKSRARE_STRATEGY_FIXED_PRICE]),
        ],
        extraData: ethers.constants.HashZero,
      },
    ];

    const tx = await aggregator
      .connect(buyer)
      .execute([], tradeData, buyer.address, buyer.address, false, { value: totalValue });
    const receipt = await tx.wait();
    validateSweepEvent(receipt, buyer.address);

    expect(await bayc.balanceOf(aggregator.address)).to.equal(0);
    expect(await bayc.balanceOf(buyer.address)).to.equal(2);
    expect(await bayc.ownerOf(tokenIdOne)).to.equal(buyer.address);
    expect(await bayc.ownerOf(tokenIdTwo)).to.equal(buyer.address);
  });

  it("is able to refund extra ETH paid", async function () {
    const { aggregator, proxy, functionSelector, buyer, bayc } = await loadFixture(deployLooksRareFixture);

    const { getBalance } = ethers.provider;

    const abiCoder = ethers.utils.defaultAbiCoder;

    const priceOne = ethers.utils.parseEther("81.8");
    const priceTwo = ethers.utils.parseEther("83.391");
    const totalValue = priceOne.add(priceTwo);

    const tradeData = [
      {
        proxy: proxy.address,
        selector: functionSelector,
        value: totalValue,
        maxFeeBp: 0,
        orders: [
          {
            signer: "0x2137213d50207Edfd92bCf4CF7eF9E491A155357",
            collection: BAYC,
            collectionType: 0,
            tokenIds: [tokenIdOne],
            amounts: [1],
            price: priceOne,
            currency: WETH,
            startTime: 1659632508,
            endTime: 1662186976,
            signature:
              "0xe669f75ee8768c3dc4a7ac11f2d301f9dbfced5c1f3c13c7f445ad84d326db4b0f2da0827bac814c4ed782b661ef40dcb2fa71141ef8239a5e5f1038e117549c1c",
          },
          {
            signer: "0xaf0f4479aF9Df756b9b2c69B463214B9a3346443",
            collection: BAYC,
            collectionType: 0,
            tokenIds: [tokenIdTwo],
            amounts: [1],
            price: priceTwo,
            currency: WETH,
            startTime: 1659484473,
            endTime: 1660089268,
            signature:
              "0x146a8f500fea9cde68c339da9abe8654ffb60c5a80506532e3500d1edba687640519093ff36ab3a728c961fc763d6e6a107ed823cfa5bd45182cab8029dab5d21b",
          },
        ],
        ordersExtraData: [
          abiCoder.encode(LOOKSRARE_EXTRA_DATA_SCHEMA, [priceOne, 9550, 0, LOOKSRARE_STRATEGY_FIXED_PRICE]),
          abiCoder.encode(LOOKSRARE_EXTRA_DATA_SCHEMA, [priceTwo, 8500, 50, LOOKSRARE_STRATEGY_FIXED_PRICE]),
        ],
        extraData: ethers.constants.HashZero,
      },
    ];

    const buyerBalanceBefore = await getBalance(buyer.address);

    const tx = await aggregator.connect(buyer).execute([], tradeData, buyer.address, buyer.address, false, {
      value: totalValue.add(ethers.constants.WeiPerEther),
    });
    const receipt = await tx.wait();
    const txFee = await calculateTxFee(tx);

    validateSweepEvent(receipt, buyer.address);

    expect(await bayc.balanceOf(aggregator.address)).to.equal(0);
    expect(await bayc.balanceOf(buyer.address)).to.equal(2);
    expect(await bayc.ownerOf(tokenIdOne)).to.equal(buyer.address);
    expect(await bayc.ownerOf(tokenIdTwo)).to.equal(buyer.address);
    expect(await getBalance(aggregator.address)).to.equal(0);
    expect(await getBalance(proxy.address)).to.equal(0);
    const buyerBalanceAfter = await getBalance(buyer.address);
    expect(buyerBalanceBefore.sub(buyerBalanceAfter).sub(txFee)).to.equal(totalValue);
  });

  it("is able to handle partial trades", async function () {
    const { aggregator, proxy, functionSelector, buyer, bayc } = await loadFixture(deployLooksRareFixture);

    const { getBalance } = ethers.provider;

    const abiCoder = ethers.utils.defaultAbiCoder;

    const priceOne = ethers.utils.parseEther("81.8");
    const totalValue = priceOne.add(priceOne);

    const orderOneJson = {
      signer: "0x2137213d50207Edfd92bCf4CF7eF9E491A155357",
      collection: BAYC,
      collectionType: 0,
      tokenIds: [tokenIdOne],
      amounts: [1],
      price: priceOne,
      currency: WETH,
      startTime: 1659632508,
      endTime: 1662186976,
      signature:
        "0xe669f75ee8768c3dc4a7ac11f2d301f9dbfced5c1f3c13c7f445ad84d326db4b0f2da0827bac814c4ed782b661ef40dcb2fa71141ef8239a5e5f1038e117549c1c",
    };

    const tradeData = [
      {
        proxy: proxy.address,
        selector: functionSelector,
        value: totalValue,
        maxFeeBp: 0,
        orders: [orderOneJson, orderOneJson],
        ordersExtraData: [
          abiCoder.encode(LOOKSRARE_EXTRA_DATA_SCHEMA, [priceOne, 9550, 0, LOOKSRARE_STRATEGY_FIXED_PRICE]),
          abiCoder.encode(LOOKSRARE_EXTRA_DATA_SCHEMA, [priceOne, 9550, 0, LOOKSRARE_STRATEGY_FIXED_PRICE]),
        ],
        extraData: ethers.constants.HashZero,
      },
    ];

    const buyerBalanceBefore = await getBalance(buyer.address);

    const tx = await aggregator
      .connect(buyer)
      .execute([], tradeData, buyer.address, buyer.address, false, { value: totalValue });
    const receipt = await tx.wait();
    const txFee = await calculateTxFee(tx);

    validateSweepEvent(receipt, buyer.address);

    expect(await bayc.balanceOf(aggregator.address)).to.equal(0);
    expect(await bayc.balanceOf(buyer.address)).to.equal(1);
    expect(await bayc.ownerOf(tokenIdOne)).to.equal(buyer.address);
    expect(await getBalance(aggregator.address)).to.equal(0);
    expect(await getBalance(proxy.address)).to.equal(0);
    const buyerBalanceAfter = await getBalance(buyer.address);
    expect(buyerBalanceBefore.sub(buyerBalanceAfter).sub(txFee)).to.equal(priceOne);
  });

  it("is able to handle atomic trades", async function () {
    const { aggregator, proxy, functionSelector, buyer, bayc } = await loadFixture(deployLooksRareFixture);

    const { getBalance } = ethers.provider;

    const abiCoder = ethers.utils.defaultAbiCoder;

    const priceOne = ethers.utils.parseEther("81.8");
    const totalValue = priceOne.add(priceOne);

    const orderOneJson = {
      signer: "0x2137213d50207Edfd92bCf4CF7eF9E491A155357",
      collection: BAYC,
      collectionType: 0,
      tokenIds: [tokenIdOne],
      amounts: [1],
      price: priceOne,
      currency: WETH,
      startTime: 1659632508,
      endTime: 1662186976,
      signature:
        "0xe669f75ee8768c3dc4a7ac11f2d301f9dbfced5c1f3c13c7f445ad84d326db4b0f2da0827bac814c4ed782b661ef40dcb2fa71141ef8239a5e5f1038e117549c1c",
    };

    const tradeData = [
      {
        proxy: proxy.address,
        selector: functionSelector,
        value: totalValue,
        maxFeeBp: 0,
        orders: [orderOneJson, orderOneJson],
        ordersExtraData: [
          abiCoder.encode(LOOKSRARE_EXTRA_DATA_SCHEMA, [priceOne, 9550, 0, LOOKSRARE_STRATEGY_FIXED_PRICE]),
          abiCoder.encode(LOOKSRARE_EXTRA_DATA_SCHEMA, [priceOne, 9550, 0, LOOKSRARE_STRATEGY_FIXED_PRICE]),
        ],
        extraData: ethers.constants.HashZero,
      },
    ];

    const buyerBalanceBefore = await getBalance(buyer.address);

    await expect(
      aggregator.connect(buyer).execute([], tradeData, buyer.address, buyer.address, true, { value: totalValue })
    ).to.be.revertedWith("Order: Matching order expired");

    expect(await bayc.balanceOf(aggregator.address)).to.equal(0);
    expect(await bayc.balanceOf(buyer.address)).to.equal(0);
    expect(await getBalance(aggregator.address)).to.equal(0);
    expect(await getBalance(proxy.address)).to.equal(0);
    const buyerBalanceAfter = await getBalance(buyer.address);
    expect(buyerBalanceBefore.sub(buyerBalanceAfter)).to.be.lt(ethers.utils.parseEther("0.005"));
  });
});
