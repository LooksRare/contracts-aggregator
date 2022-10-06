import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import deployCryptoPunksFixture from "./fixtures/deploy-cryptopunks-fixture";
import { CRYPTOPUNKS } from "../constants";
import { expect } from "chai";
import calculateTxFee from "./utils/calculate-tx-fee";
import validateSweepEvent from "./utils/validate-sweep-event";

describe("LooksRareAggregator", () => {
  const tokenIdOne = "3149";
  const tokenIdTwo = "2675";

  it("Should be able to handle CryptoPunks trades", async function () {
    const { aggregator, proxy, functionSelector, buyer, cryptopunks } = await loadFixture(deployCryptoPunksFixture);

    const { AddressZero, HashZero } = ethers.constants;

    const priceOne = ethers.utils.parseEther("68.5");
    const priceTwo = ethers.utils.parseEther("69.5");

    const totalValue = priceOne.add(priceTwo);

    const baseOrder = {
      signer: AddressZero,
      collection: CRYPTOPUNKS,
      collectionType: 0,
      amounts: [1],
      currency: AddressZero,
      startTime: 0,
      endTime: 0,
      signature: HashZero,
    };

    const tx = await aggregator.connect(buyer).execute(
      [],
      [
        {
          proxy: proxy.address,
          selector: functionSelector,
          value: totalValue,
          maxFeeBp: 0,
          orders: [
            {
              // eslint-disable-next-line node/no-unsupported-features/es-syntax
              ...baseOrder,
              price: priceOne,
              tokenIds: [tokenIdOne],
            },
            {
              // eslint-disable-next-line node/no-unsupported-features/es-syntax
              ...baseOrder,
              price: priceTwo,
              tokenIds: [tokenIdTwo],
            },
          ],
          ordersExtraData: [HashZero, HashZero],
          extraData: HashZero,
        },
      ],
      buyer.address,
      buyer.address,
      false,
      { value: totalValue }
    );
    const receipt = await tx.wait();
    validateSweepEvent(receipt, buyer.address);

    expect(await cryptopunks.balanceOf(buyer.address)).to.equal(2);
    expect(await cryptopunks.punkIndexToAddress(tokenIdOne)).to.equal(buyer.address);
    expect(await cryptopunks.punkIndexToAddress(tokenIdTwo)).to.equal(buyer.address);
  });

  // Trying to crash the second trade by buying the same NFT twice, but the first trade should still go through
  // and there should be a refund for the second trade.
  it("Should be able to handle partial trades", async function () {
    const { aggregator, proxy, functionSelector, buyer, cryptopunks } = await loadFixture(deployCryptoPunksFixture);

    const { AddressZero, HashZero } = ethers.constants;
    const { getBalance } = ethers.provider;

    const priceOne = ethers.utils.parseEther("68.5");
    const priceTwo = ethers.utils.parseEther("69.5");

    const totalValue = priceOne.add(priceTwo);

    const baseOrder = {
      signer: AddressZero,
      collection: CRYPTOPUNKS,
      collectionType: 0,
      amounts: [1],
      currency: AddressZero,
      startTime: 0,
      endTime: 0,
      signature: HashZero,
    };

    const buyerBalanceBefore = await getBalance(buyer.address);

    const tx = await aggregator.execute(
      [],
      [
        {
          proxy: proxy.address,
          selector: functionSelector,
          value: totalValue.add(priceOne),
          maxFeeBp: 0,
          orders: [
            {
              // eslint-disable-next-line node/no-unsupported-features/es-syntax
              ...baseOrder,
              price: priceOne,
              tokenIds: [tokenIdOne],
            },
            {
              // eslint-disable-next-line node/no-unsupported-features/es-syntax
              ...baseOrder,
              price: priceTwo,
              tokenIds: [tokenIdTwo],
            },
            {
              // eslint-disable-next-line node/no-unsupported-features/es-syntax
              ...baseOrder,
              price: priceOne,
              tokenIds: [tokenIdOne],
            },
          ],
          ordersExtraData: [HashZero, HashZero, HashZero],
          extraData: HashZero,
        },
      ],
      buyer.address,
      buyer.address,
      false,
      { value: totalValue.add(priceOne) }
    );
    const receipt = await tx.wait();
    const txFee = await calculateTxFee(tx);
    validateSweepEvent(receipt, buyer.address);

    expect(await cryptopunks.balanceOf(buyer.address)).to.equal(2);
    expect(await cryptopunks.punkIndexToAddress(tokenIdOne)).to.equal(buyer.address);
    expect(await cryptopunks.punkIndexToAddress(tokenIdTwo)).to.equal(buyer.address);

    expect(await getBalance(aggregator.address)).to.equal(0);
    expect(await getBalance(proxy.address)).to.equal(0);
    const buyerBalanceAfter = await getBalance(buyer.address);
    expect(buyerBalanceBefore.sub(buyerBalanceAfter).sub(txFee)).to.equal(totalValue);
  });

  it("Should be able to handle atomic trades", async function () {
    const { aggregator, proxy, functionSelector, buyer, cryptopunks } = await loadFixture(deployCryptoPunksFixture);

    const { AddressZero, HashZero } = ethers.constants;
    const { getBalance } = ethers.provider;

    const priceOne = ethers.utils.parseEther("68.5");
    const priceTwo = ethers.utils.parseEther("69.5");

    const totalValue = priceOne.add(priceTwo);

    const baseOrder = {
      signer: AddressZero,
      collection: CRYPTOPUNKS,
      collectionType: 0,
      amounts: [1],
      currency: AddressZero,
      startTime: 0,
      endTime: 0,
      signature: HashZero,
    };

    const buyerBalanceBefore = await getBalance(buyer.address);

    await expect(
      aggregator.connect(buyer).execute(
        [],
        [
          {
            proxy: proxy.address,
            selector: functionSelector,
            value: totalValue.add(priceOne),
            maxFeeBp: 0,
            orders: [
              {
                // eslint-disable-next-line node/no-unsupported-features/es-syntax
                ...baseOrder,
                price: priceOne,
                tokenIds: [tokenIdOne],
              },
              {
                // eslint-disable-next-line node/no-unsupported-features/es-syntax
                ...baseOrder,
                price: priceTwo,
                tokenIds: [tokenIdTwo],
              },
              {
                // eslint-disable-next-line node/no-unsupported-features/es-syntax
                ...baseOrder,
                price: priceOne,
                tokenIds: [tokenIdOne],
              },
            ],
            ordersExtraData: [HashZero, HashZero, HashZero],
            extraData: HashZero,
          },
        ],
        buyer.address,
        buyer.address,
        true,
        { value: totalValue.add(priceOne) }
      )
    ).to.be.reverted;

    expect(await cryptopunks.balanceOf(buyer.address)).to.equal(0);

    expect(await getBalance(aggregator.address)).to.equal(0);
    expect(await getBalance(proxy.address)).to.equal(0);
    const buyerBalanceAfter = await getBalance(buyer.address);
    expect(buyerBalanceBefore.sub(buyerBalanceAfter)).to.be.lt(ethers.utils.parseEther("0.005"));
  });
});
