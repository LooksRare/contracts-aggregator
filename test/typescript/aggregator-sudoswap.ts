import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import deploySudoswapFixture from "./fixtures/deploy-sudoswap-fixture";
import calculateTxFee from "./utils/calculate-tx-fee";
import validateSweepEvent from "./utils/validate-sweep-event";

describe("Aggregator", () => {
  it("Should be able to handle Sudoswap trades", async function () {
    const { aggregator, proxy, buyer, functionSelector, moodie } = await loadFixture(deploySudoswapFixture);
    // This is the function to call to get the price to pay on mainnet.
    // (error, , , pairCost, ) = swapList[i].swapInfo.pair.getBuyNFTQuote(
    //   swapList[i].swapInfo.numItems
    // );
    const maxCostOne = BigNumber.from("221649999999999993");
    const maxCostTwo = BigNumber.from("221650000000000000");
    const price = maxCostOne.add(maxCostTwo);

    const { HashZero, AddressZero } = ethers.constants;
    const tradeData = [
      {
        proxy: proxy.address,
        selector: functionSelector,
        value: price,
        orders: [
          {
            signer: AddressZero,
            recipient: buyer.address,
            collection: "0x0f23939ee95350f26d9c1b818ee0cc1c8fd2b99d",
            collectionType: 0,
            tokenIds: [5536],
            amounts: [1],
            price: maxCostOne,
            currency: AddressZero,
            startTime: 0,
            endTime: 0,
            signature: HashZero,
          },
          {
            signer: AddressZero,
            recipient: buyer.address,
            collection: "0x4d1ffe3eb76f15d1f7651adf322e1f5a6e5c7552",
            collectionType: 0,
            tokenIds: [1915],
            amounts: [1],
            price: maxCostTwo,
            currency: AddressZero,
            startTime: 0,
            endTime: 0,
            signature: HashZero,
          },
        ],
        ordersExtraData: [HashZero, HashZero],
        extraData: HashZero,
      },
    ];

    const tx = await aggregator.connect(buyer).buyWithETH(tradeData, false, { value: price });
    const receipt = await tx.wait();

    validateSweepEvent(receipt, buyer.address, 1, 1);

    expect(await moodie.balanceOf(buyer.address)).to.equal(2);
    expect(await moodie.ownerOf(5536)).to.equal(buyer.address);
    expect(await moodie.ownerOf(1915)).to.equal(buyer.address);
  });

  it("is able to refund extra ETH paid", async function () {
    const { aggregator, proxy, buyer, functionSelector, moodie } = await loadFixture(deploySudoswapFixture);
    const maxCostOne = BigNumber.from("221649999999999993");
    const maxCostTwo = BigNumber.from("221650000000000000");
    const price = ethers.utils.parseEther("1");

    const { HashZero, AddressZero } = ethers.constants;
    const tradeData = [
      {
        proxy: proxy.address,
        selector: functionSelector,
        value: price,
        orders: [
          {
            signer: AddressZero,
            recipient: buyer.address,
            collection: "0x0f23939ee95350f26d9c1b818ee0cc1c8fd2b99d",
            collectionType: 0,
            tokenIds: [5536],
            amounts: [1],
            price: maxCostOne.mul(2),
            currency: AddressZero,
            startTime: 0,
            endTime: 0,
            signature: HashZero,
          },
          {
            signer: AddressZero,
            recipient: buyer.address,
            collection: "0x4d1ffe3eb76f15d1f7651adf322e1f5a6e5c7552",
            collectionType: 0,
            tokenIds: [1915],
            amounts: [1],
            price: maxCostTwo.mul(2),
            currency: AddressZero,
            startTime: 0,
            endTime: 0,
            signature: HashZero,
          },
        ],
        ordersExtraData: [HashZero, HashZero],
        extraData: HashZero,
      },
    ];

    const buyerBalanceBefore = await ethers.provider.getBalance(buyer.address);

    const tx = await aggregator.connect(buyer).buyWithETH(tradeData, false, { value: price });
    const receipt = await tx.wait();
    const txFee = await calculateTxFee(tx);

    validateSweepEvent(receipt, buyer.address, 1, 1);

    expect(await moodie.balanceOf(buyer.address)).to.equal(2);
    expect(await moodie.ownerOf(5536)).to.equal(buyer.address);
    expect(await moodie.ownerOf(1915)).to.equal(buyer.address);
    expect(await ethers.provider.getBalance(aggregator.address)).to.equal(0);
    expect(await ethers.provider.getBalance(proxy.address)).to.equal(0);
    const buyerBalanceAfter = await ethers.provider.getBalance(buyer.address);
    expect(buyerBalanceBefore.sub(buyerBalanceAfter).sub(txFee)).to.equal(maxCostOne.add(maxCostTwo));
  });
});
