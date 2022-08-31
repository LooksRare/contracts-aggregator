import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import deploySudoswapFixture from "./fixtures/deploy-sudoswap-fixture";
import calculateTxFee from "./utils/calculate-tx-fee";
import validateSweepEvent from "./utils/validate-sweep-event";

describe("Aggregator", () => {
  const sudoswapPairOne = "0x0f23939ee95350f26d9c1b818ee0cc1c8fd2b99d";
  const sudoswapPairTwo = "0x4d1ffe3eb76f15d1f7651adf322e1f5a6e5c7552";
  const tokenIdOne = 5536;
  const tokenIdTwo = 1915;
  const maxCostOne = BigNumber.from("221649999999999993");
  // This is the function to call to get the price to pay on mainnet.
  // (error, , , pairCost, ) = swapList[i].swapInfo.pair.getBuyNFTQuote(
  //   swapList[i].swapInfo.numItems
  // );
  it("Should be able to handle Sudoswap trades", async function () {
    const { aggregator, proxy, buyer, functionSelector, moodie } = await loadFixture(deploySudoswapFixture);
    const maxCostTwo = BigNumber.from("221650000000000000");
    const price = maxCostOne.add(maxCostTwo);

    const { HashZero, AddressZero } = ethers.constants;
    const baseOrder = {
      signer: AddressZero,
      collectionType: 0,
      amounts: [1],
      currency: AddressZero,
      startTime: 0,
      endTime: 0,
      signature: HashZero,
    };
    const tradeData = [
      {
        proxy: proxy.address,
        selector: functionSelector,
        value: price,
        orders: [
          {
            collection: sudoswapPairOne,
            tokenIds: [tokenIdOne],
            price: maxCostOne,
            // eslint-disable-next-line node/no-unsupported-features/es-syntax
            ...baseOrder,
          },
          {
            collection: sudoswapPairTwo,
            tokenIds: [tokenIdTwo],
            price: maxCostTwo,
            // eslint-disable-next-line node/no-unsupported-features/es-syntax
            ...baseOrder,
          },
        ],
        ordersExtraData: [HashZero, HashZero],
        extraData: HashZero,
        tokenTransfers: [],
      },
    ];

    const tx = await aggregator.connect(buyer).execute(tradeData, buyer.address, false, { value: price });
    const receipt = await tx.wait();

    validateSweepEvent(receipt, buyer.address, 1, 1);

    expect(await moodie.balanceOf(buyer.address)).to.equal(2);
    expect(await moodie.ownerOf(tokenIdOne)).to.equal(buyer.address);
    expect(await moodie.ownerOf(tokenIdTwo)).to.equal(buyer.address);
  });

  it("Should be able to handle atomic Sudoswap trades", async function () {
    const { aggregator, proxy, buyer, functionSelector } = await loadFixture(deploySudoswapFixture);
    const maxCostTwo = BigNumber.from("221649999999999999"); // 1 wei less than required
    const price = maxCostOne.add(maxCostTwo);

    const { HashZero, AddressZero } = ethers.constants;
    const baseOrder = {
      signer: AddressZero,
      collectionType: 0,
      amounts: [1],
      currency: AddressZero,
      startTime: 0,
      endTime: 0,
      signature: HashZero,
    };
    const tradeData = [
      {
        proxy: proxy.address,
        selector: functionSelector,
        value: price,
        orders: [
          {
            collection: sudoswapPairOne,
            tokenIds: [tokenIdOne],
            price: maxCostOne,
            // eslint-disable-next-line node/no-unsupported-features/es-syntax
            ...baseOrder,
          },
          {
            collection: sudoswapPairTwo,
            tokenIds: [tokenIdTwo],
            price: maxCostTwo,
            // eslint-disable-next-line node/no-unsupported-features/es-syntax
            ...baseOrder,
          },
        ],
        ordersExtraData: [HashZero, HashZero],
        extraData: HashZero,
        tokenTransfers: [],
      },
    ];

    await expect(
      aggregator.connect(buyer).execute(tradeData, buyer.address, true, { value: price })
    ).to.be.revertedWith("TradeExecutionFailed()");
  });

  it("Should be able to handle partial Sudoswap trades", async function () {
    const { aggregator, proxy, buyer, functionSelector, moodie } = await loadFixture(deploySudoswapFixture);
    const maxCostTwo = BigNumber.from("221649999999999999"); // 1 wei less than required
    const price = maxCostOne.add(maxCostTwo);

    const { HashZero, AddressZero } = ethers.constants;
    const baseOrder = {
      signer: AddressZero,
      collectionType: 0,
      amounts: [1],
      currency: AddressZero,
      startTime: 0,
      endTime: 0,
      signature: HashZero,
    };
    const tradeData = [
      {
        proxy: proxy.address,
        selector: functionSelector,
        value: price,
        orders: [
          {
            collection: sudoswapPairOne,
            tokenIds: [tokenIdOne],
            price: maxCostOne,
            // eslint-disable-next-line node/no-unsupported-features/es-syntax
            ...baseOrder,
          },
          {
            collection: sudoswapPairTwo,
            tokenIds: [tokenIdTwo],
            price: maxCostTwo,
            // eslint-disable-next-line node/no-unsupported-features/es-syntax
            ...baseOrder,
          },
        ],
        ordersExtraData: [HashZero, HashZero],
        extraData: HashZero,
        tokenTransfers: [],
      },
    ];

    const tx = await aggregator.connect(buyer).execute(tradeData, buyer.address, false, { value: price });
    const receipt = await tx.wait();

    validateSweepEvent(receipt, buyer.address, 1, 1);

    expect(await moodie.balanceOf(buyer.address)).to.equal(1);
    expect(await moodie.ownerOf(tokenIdOne)).to.equal(buyer.address);
  });

  it("is able to refund extra ETH paid", async function () {
    const { aggregator, proxy, buyer, functionSelector, moodie } = await loadFixture(deploySudoswapFixture);
    const { getBalance } = ethers.provider;
    const maxCostTwo = BigNumber.from("221650000000000000");
    const price = ethers.utils.parseEther("1");

    const { HashZero, AddressZero } = ethers.constants;
    const baseOrder = {
      signer: AddressZero,
      collectionType: 0,
      amounts: [1],
      currency: AddressZero,
      startTime: 0,
      endTime: 0,
      signature: HashZero,
    };
    const tradeData = [
      {
        proxy: proxy.address,
        selector: functionSelector,
        value: price,
        orders: [
          {
            collection: sudoswapPairOne,
            tokenIds: [tokenIdOne],
            price: maxCostOne.mul(2),
            // eslint-disable-next-line node/no-unsupported-features/es-syntax
            ...baseOrder,
          },
          {
            collection: sudoswapPairTwo,
            tokenIds: [tokenIdTwo],
            price: maxCostTwo.mul(2),
            // eslint-disable-next-line node/no-unsupported-features/es-syntax
            ...baseOrder,
          },
        ],
        ordersExtraData: [HashZero, HashZero],
        extraData: HashZero,
        tokenTransfers: [],
      },
    ];

    const buyerBalanceBefore = await getBalance(buyer.address);

    const tx = await aggregator.connect(buyer).execute(tradeData, buyer.address, false, { value: price });
    const receipt = await tx.wait();
    const txFee = await calculateTxFee(tx);

    validateSweepEvent(receipt, buyer.address, 1, 1);

    expect(await moodie.balanceOf(buyer.address)).to.equal(2);
    expect(await moodie.ownerOf(tokenIdOne)).to.equal(buyer.address);
    expect(await moodie.ownerOf(tokenIdTwo)).to.equal(buyer.address);
    expect(await getBalance(aggregator.address)).to.equal(0);
    expect(await getBalance(proxy.address)).to.equal(0);
    const buyerBalanceAfter = await getBalance(buyer.address);
    expect(buyerBalanceBefore.sub(buyerBalanceAfter).sub(txFee)).to.equal(maxCostOne.add(maxCostTwo));
  });
});
