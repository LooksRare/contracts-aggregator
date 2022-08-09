import { expect } from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";
import { ethers } from "hardhat";
import { BAYC, LOOKSRARE_STRATEGY_FIXED_PRICE, WETH } from "../constants";
import getSignature from "./utils/get-signature";

describe("LooksRareAggregator", () => {
  let aggregator: Contract;
  let proxy: Contract;
  let bayc: Contract;
  let buyer: SignerWithAddress;
  let functionSelector: string;

  beforeEach(async () => {
    const Aggregator = await ethers.getContractFactory("LooksRareAggregator");
    aggregator = await Aggregator.deploy();
    await aggregator.deployed();

    const LooksRareV2Proxy = await ethers.getContractFactory("LooksRareV2Proxy");
    proxy = await LooksRareV2Proxy.deploy();
    await proxy.deployed();

    functionSelector = await getSignature("LooksRareV2Proxy.json", "buyWithETH");
    await aggregator.addFunction(proxy.address, functionSelector);

    [buyer] = await ethers.getSigners();

    await ethers.provider.send("hardhat_setBalance", [
      buyer.address,
      ethers.utils.parseEther("200").toHexString().replace("0x0", "0x"),
    ]);

    bayc = await ethers.getContractAt("IERC721", BAYC);
  });

  it("Should be able to handle LooksRare V2 trades (matchAskWithTakerBidUsingETHAndWETH)", async function () {
    const abiCoder = ethers.utils.defaultAbiCoder;

    const priceOne = ethers.utils.parseEther("81.8");
    const priceTwo = ethers.utils.parseEther("83.391");
    const totalValue = priceOne.add(priceTwo);

    const tokenIdOne = 7139;
    const tokenIdTwo = 3939;

    const extraDataSchema = ["address", "uint256", "uint256"];

    const tradeData = [
      {
        proxy: proxy.address,
        selector: functionSelector,
        value: totalValue,
        orders: [
          {
            signer: "0x2137213d50207Edfd92bCf4CF7eF9E491A155357",
            recipient: buyer.address,
            collection: BAYC,
            tokenId: tokenIdOne,
            amount: 1,
            price: priceOne,
            currency: WETH,
            startTime: 1659632508,
            endTime: 1662186976,
            signature:
              "0xe669f75ee8768c3dc4a7ac11f2d301f9dbfced5c1f3c13c7f445ad84d326db4b0f2da0827bac814c4ed782b661ef40dcb2fa71141ef8239a5e5f1038e117549c1c",
          },
          {
            signer: "0xaf0f4479aF9Df756b9b2c69B463214B9a3346443",
            recipient: buyer.address,
            collection: BAYC,
            tokenId: tokenIdTwo,
            amount: 1,
            price: priceTwo,
            currency: WETH,
            startTime: 1659484473,
            endTime: 1660089268,
            signature:
              "0x146a8f500fea9cde68c339da9abe8654ffb60c5a80506532e3500d1edba687640519093ff36ab3a728c961fc763d6e6a107ed823cfa5bd45182cab8029dab5d21b",
          },
        ],
        ordersExtraData: [
          abiCoder.encode(extraDataSchema, [LOOKSRARE_STRATEGY_FIXED_PRICE, 0, 9550]),
          abiCoder.encode(extraDataSchema, [LOOKSRARE_STRATEGY_FIXED_PRICE, 50, 8500]),
        ],
        extraData: "0x",
      },
    ];

    const tx = await aggregator.connect(buyer).buyWithETH(tradeData, { value: totalValue });
    await tx.wait();

    expect(await bayc.balanceOf(aggregator.address)).to.equal(0);
    expect(await bayc.balanceOf(buyer.address)).to.equal(2);
    expect(await bayc.ownerOf(tokenIdOne)).to.equal(buyer.address);
    expect(await bayc.ownerOf(tokenIdTwo)).to.equal(buyer.address);
  });
});
