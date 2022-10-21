import { expect } from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";
import { ethers } from "hardhat";
import { BAYC, LOOKSRARE_STRATEGY_FIXED_PRICE, WETH } from "../../constants";
import getSignature from "../utils/get-signature";
import getAbi from "../utils/get-abi";

describe("V0Aggregator", () => {
  let aggregator: Contract;
  let proxy: Contract;
  let bayc: Contract;
  let buyer: SignerWithAddress;

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

  beforeEach(async () => {
    const Aggregator = await ethers.getContractFactory("V0Aggregator");
    aggregator = await Aggregator.deploy();
    await aggregator.deployed();

    const V0LooksRareProxy = await ethers.getContractFactory("V0LooksRareProxy");
    proxy = await V0LooksRareProxy.deploy();
    await proxy.deployed();

    const functionSelector = getSignature("V0LooksRareProxy.json", "execute");
    await aggregator.addFunction(proxy.address, functionSelector);

    [buyer] = await ethers.getSigners();

    await ethers.provider.send("hardhat_setBalance", [
      buyer.address,
      ethers.utils.parseEther("200").toHexString().replace("0x0", "0x"),
    ]);

    bayc = await ethers.getContractAt(
      "@looksrare/contracts-libs/contracts/interfaces/generic/IERC721.sol:IERC721",
      BAYC
    );
  });

  it("Should be able to handle LooksRare V1 trades (matchAskWithTakerBidUsingETHAndWETH)", async function () {
    const priceOne = ethers.utils.parseEther("81.8");
    const priceTwo = ethers.utils.parseEther("83.391");

    const tokenIdOne = 7139;
    const tokenIdTwo = 3939;

    const minPercentageToAskOne = 9550;
    const minPercentageToAskTwo = 8500;

    const takerBidOne = {
      isOrderAsk: false,
      taker: proxy.address,
      price: priceOne,
      tokenId: tokenIdOne,
      minPercentageToAsk: minPercentageToAskOne,
      params: "0x",
    };

    const takerBidTwo = {
      isOrderAsk: false,
      taker: proxy.address,
      price: priceTwo,
      tokenId: tokenIdTwo,
      minPercentageToAsk: minPercentageToAskTwo,
      params: "0x",
    };

    const signatureOne =
      "0xe669f75ee8768c3dc4a7ac11f2d301f9dbfced5c1f3c13c7f445ad84d326db4b0f2da0827bac814c4ed782b661ef40dcb2fa71141ef8239a5e5f1038e117549c1c";
    const expandedSignatureOne = ethers.utils.splitSignature(signatureOne);

    const makerAskOne = {
      isOrderAsk: true,
      signer: "0x2137213d50207Edfd92bCf4CF7eF9E491A155357",
      collection: BAYC,
      price: priceOne,
      tokenId: tokenIdOne,
      amount: 1,
      strategy: LOOKSRARE_STRATEGY_FIXED_PRICE,
      currency: WETH,
      nonce: 0,
      startTime: 1659632508,
      endTime: 1662186976,
      minPercentageToAsk: minPercentageToAskOne,
      params: "0x",
      v: expandedSignatureOne.v,
      r: expandedSignatureOne.r,
      s: expandedSignatureOne.s,
    };

    const signatureTwo =
      "0x146a8f500fea9cde68c339da9abe8654ffb60c5a80506532e3500d1edba687640519093ff36ab3a728c961fc763d6e6a107ed823cfa5bd45182cab8029dab5d21b";
    const expandedSignatureTwo = ethers.utils.splitSignature(signatureTwo);

    const makerAskTwo = {
      isOrderAsk: true,
      signer: "0xaf0f4479aF9Df756b9b2c69B463214B9a3346443",
      collection: BAYC,
      price: priceTwo,
      tokenId: tokenIdTwo,
      amount: 1,
      strategy: LOOKSRARE_STRATEGY_FIXED_PRICE,
      currency: WETH,
      nonce: 50,
      startTime: 1659484473,
      endTime: 1660089268,
      minPercentageToAsk: minPercentageToAskTwo,
      params: "0x",
      v: expandedSignatureTwo.v,
      r: expandedSignatureTwo.r,
      s: expandedSignatureTwo.s,
    };

    const abi = getAbi("V0LooksRareProxy.json");
    const iface = new ethers.utils.Interface(abi);

    const calldata = iface.encodeFunctionData("execute", [
      [takerBidOne, takerBidTwo],
      [makerAskOne, makerAskTwo],
      buyer.address,
    ]);

    const totalValue = priceOne.add(priceTwo);
    const tx = await aggregator.connect(buyer).execute([{ proxy: proxy.address, data: calldata, value: totalValue }], {
      value: totalValue,
    });
    await tx.wait();

    expect(await bayc.balanceOf(aggregator.address)).to.equal(0);
    expect(await bayc.balanceOf(buyer.address)).to.equal(2);
    expect(await bayc.ownerOf(tokenIdOne)).to.equal(buyer.address);
    expect(await bayc.ownerOf(tokenIdTwo)).to.equal(buyer.address);
  });
});
