import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";
import { BAYC, FULFILLER_CONDUIT_KEY, LOOKSRARE_STRATEGY_FIXED_PRICE, SEAPORT, WETH } from "../constants";
import * as fs from "fs";
import * as path from "path";

describe("Aggregator", () => {
  let aggregator: Contract;
  let proxy: Contract;
  let bayc: Contract;
  let buyer: SignerWithAddress;

  beforeEach(async () => {
    const Aggregator = await ethers.getContractFactory("Aggregator");
    aggregator = await Aggregator.deploy();
    await aggregator.deployed();

    const LooksRareV1Proxy = await ethers.getContractFactory("LooksRareV1Proxy");
    proxy = await LooksRareV1Proxy.deploy();
    await proxy.deployed();

    // LooksRareV1Proxy buyWithETH
    await aggregator.addFunction(proxy.address, "0x96792461");

    // Seaport 1.1 fulfillAvailableAdvancedOrders
    await aggregator.addFunction(SEAPORT, "0x87201b41");

    [buyer] = await ethers.getSigners();

    await ethers.provider.send("hardhat_setBalance", [
      buyer.address,
      ethers.utils.parseEther("400").toHexString().replace("0x0", "0x"),
    ]);

    bayc = await ethers.getContractAt("IERC721", BAYC);
  });

  it("Should be able to handle LooksRare/OpenSea trades together", async function () {
    const orderOne = JSON.parse(
      await fs.readFileSync(path.join(__dirname, "./fixtures/bayc-2518-order.json"), { encoding: "utf8", flag: "r" })
    );

    const orderTwo = JSON.parse(
      await fs.readFileSync(path.join(__dirname, "./fixtures/bayc-8498-order.json"), { encoding: "utf8", flag: "r" })
    );

    const offerFulfillments = [[{ orderIndex: 0, itemIndex: 0 }], [{ orderIndex: 1, itemIndex: 0 }]];

    const considerationFulfillments = [
      // seller one
      [{ orderIndex: 0, itemIndex: 0 }],
      // seller two
      [{ orderIndex: 1, itemIndex: 0 }],
      // OpenSea: Fees
      [
        { orderIndex: 0, itemIndex: 1 },
        { orderIndex: 1, itemIndex: 1 },
      ],
      // royalty
      [
        { orderIndex: 0, itemIndex: 2 },
        { orderIndex: 1, itemIndex: 2 },
      ],
    ];

    const seaportAbi = JSON.parse(
      await fs.readFileSync(path.join(__dirname, "../../abis/SeaportInterface.json"), { encoding: "utf8", flag: "r" })
    );
    const seaportInterface = new ethers.utils.Interface(seaportAbi);

    const calldata = seaportInterface.encodeFunctionData("fulfillAvailableAdvancedOrders", [
      [orderOne, orderTwo],
      [],
      offerFulfillments,
      considerationFulfillments,
      FULFILLER_CONDUIT_KEY,
      buyer.address,
      2,
    ]);

    const price = ethers.utils.parseEther("84");

    const tokenIdOne = 4251;
    const tokenIdTwo = 6026;

    const minPercentageToAsk = 9550;

    const takerBidOne = {
      isOrderAsk: false,
      taker: proxy.address,
      price,
      tokenId: tokenIdOne,
      minPercentageToAsk,
      params: "0x",
    };

    const takerBidTwo = {
      isOrderAsk: false,
      taker: proxy.address,
      price,
      tokenId: tokenIdTwo,
      minPercentageToAsk,
      params: "0x",
    };

    const signatureOne =
      "0xc34d0d9cd04a7004e5d5838c75f4d53860cbd44287beac0bdd513245d6818f6e5d4c0bbce5ce1eb7dba919e277733c1b59f08fed99385d6bc6bc1af053f39fb001";
    const expandedSignatureOne = ethers.utils.splitSignature(signatureOne);

    const makerAskOne = {
      isOrderAsk: true,
      signer: "0xe51416eF43f4820Aaa2b36ddD9CfE1278106190f",
      collection: BAYC,
      price,
      tokenId: tokenIdOne,
      amount: 1,
      strategy: LOOKSRARE_STRATEGY_FIXED_PRICE,
      currency: WETH,
      nonce: 209,
      startTime: 1659529911,
      endTime: 1662121755,
      minPercentageToAsk,
      params: "0x",
      v: expandedSignatureOne.v,
      r: expandedSignatureOne.r,
      s: expandedSignatureOne.s,
    };

    const signatureTwo =
      "0x177d460a74c0adef0b4f83ec0588a8bca3bc36661828d3db6939d41333013aa211b1702fb648e7e11ba5354883aa7add92219ff907d8886b2cb0b45a81b1d2d601";
    const expandedSignatureTwo = ethers.utils.splitSignature(signatureTwo);

    const makerAskTwo = {
      isOrderAsk: true,
      signer: "0xB1Ef9318e27116ca1d97466FEf76ba66496dd558",
      collection: BAYC,
      price,
      tokenId: tokenIdTwo,
      amount: 1,
      strategy: LOOKSRARE_STRATEGY_FIXED_PRICE,
      currency: WETH,
      nonce: 1,
      startTime: 1659977872,
      endTime: 1660064095,
      minPercentageToAsk,
      params: "0x",
      v: expandedSignatureTwo.v,
      r: expandedSignatureTwo.r,
      s: expandedSignatureTwo.s,
    };

    const looksRareAbi = JSON.parse(
      await fs.readFileSync(path.join(__dirname, "../../abis/LooksRareV1Proxy.json"), { encoding: "utf8", flag: "r" })
    );
    const iface = new ethers.utils.Interface(looksRareAbi);

    const calldataLooksRare = iface.encodeFunctionData("buyWithETH", [
      [takerBidOne, takerBidTwo],
      [makerAskOne, makerAskTwo],
      buyer.address,
    ]);

    const seaportPrice = ethers.utils.parseEther("168.78");
    const looksRarePrice = ethers.utils.parseEther("168");
    const tx = await aggregator.connect(buyer).buyWithETH(
      [
        { proxy: SEAPORT, data: calldata, value: seaportPrice },
        { proxy: proxy.address, data: calldataLooksRare, value: looksRarePrice },
      ],
      { value: seaportPrice.add(looksRarePrice) }
    );

    await tx.wait();

    expect(await bayc.balanceOf(buyer.address)).to.equal(4);
    expect(await bayc.ownerOf(2518)).to.equal(buyer.address);
    expect(await bayc.ownerOf(8498)).to.equal(buyer.address);
    expect(await bayc.ownerOf(tokenIdOne)).to.equal(buyer.address);
    expect(await bayc.ownerOf(tokenIdTwo)).to.equal(buyer.address);
  });
});
