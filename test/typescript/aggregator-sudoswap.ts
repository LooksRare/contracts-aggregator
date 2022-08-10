import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, Contract } from "ethers";
import { ethers, network } from "hardhat";
import { MOODIE } from "../constants";
import calculateTxFee from "./utils/calculate-tx-fee";
import getSignature from "./utils/get-signature";

describe("Aggregator", () => {
  let aggregator: Contract;
  let proxy: Contract;
  let moodie: Contract;
  let buyer: SignerWithAddress;
  let functionSelector: string;

  beforeEach(async () => {
    const Aggregator = await ethers.getContractFactory("LooksRareAggregator");
    aggregator = await Aggregator.deploy();
    await aggregator.deployed();

    const SudoswapProxy = await ethers.getContractFactory("SudoswapProxy");
    proxy = await SudoswapProxy.deploy();
    await proxy.deployed();

    functionSelector = await getSignature("SudoswapProxy.json", "buyWithETH");
    await aggregator.addFunction(proxy.address, functionSelector);

    [buyer] = await ethers.getSigners();

    await ethers.provider.send("hardhat_setBalance", [
      buyer.address,
      ethers.utils.parseEther("200").toHexString().replace("0x0", "0x"),
    ]);

    moodie = await ethers.getContractAt("IERC721", MOODIE);
  });

  afterEach(async () => {
    await network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            jsonRpcUrl: process.env.ETH_RPC_URL,
            blockNumber: Number(process.env.FORKED_BLOCK_NUMBER),
          },
        },
      ],
    });
  });

  it("Should be able to handle Sudoswap trades", async function () {
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

    const tx = await aggregator.connect(buyer).buyWithETH(tradeData, { value: price });
    await tx.wait();

    expect(await moodie.balanceOf(buyer.address)).to.equal(2);
    expect(await moodie.ownerOf(5536)).to.equal(buyer.address);
    expect(await moodie.ownerOf(1915)).to.equal(buyer.address);
  });

  it("is able to refund extra ETH paid (trickled down to SeaportProxy)", async function () {
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

    const buyerBalanceBefore = await ethers.provider.getBalance(buyer.address);

    const tx = await aggregator.connect(buyer).buyWithETH(tradeData, { value: price });
    await tx.wait();
    const txFee = await calculateTxFee(tx);

    expect(await moodie.balanceOf(buyer.address)).to.equal(2);
    expect(await moodie.ownerOf(5536)).to.equal(buyer.address);
    expect(await moodie.ownerOf(1915)).to.equal(buyer.address);
    expect(await ethers.provider.getBalance(aggregator.address)).to.equal(0);
    expect(await ethers.provider.getBalance(proxy.address)).to.equal(0);
    const buyerBalanceAfter = await ethers.provider.getBalance(buyer.address);
    expect(buyerBalanceBefore.sub(buyerBalanceAfter).sub(txFee)).to.equal(price);
  });
});
