import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";
import {
  BAYC,
  FULFILLER_CONDUIT_KEY,
  LOOKSRARE_STRATEGY_FIXED_PRICE,
  SEAPORT,
  SEAPORT_CONSIDERATION_FULFILLMENTS_TWO_ORDERS_SAME_COLLECTION,
  SEAPORT_OFFER_FULFILLMENT_TWO_ITEMS,
  WETH,
} from "../constants";
import getAbi from "./utils/get-abi";
import getFixture from "./utils/get-fixture";
import getSignature from "./utils/get-signature";

describe("Aggregator", () => {
  let aggregator: Contract;
  let proxy: Contract;
  let bayc: Contract;
  let buyer: SignerWithAddress;

  beforeEach(async () => {
    const Aggregator = await ethers.getContractFactory("V0Aggregator");
    aggregator = await Aggregator.deploy();
    await aggregator.deployed();

    const V0LooksRareProxy = await ethers.getContractFactory("V0LooksRareProxy");
    proxy = await V0LooksRareProxy.deploy();
    await proxy.deployed();

    const looksRareSelector = getSignature("V0LooksRareProxy.json", "execute");
    await aggregator.addFunction(proxy.address, looksRareSelector);

    const seaportSelector = getSignature("SeaportInterface.json", "fulfillAvailableAdvancedOrders");
    await aggregator.addFunction(SEAPORT, seaportSelector);

    [buyer] = await ethers.getSigners();

    await ethers.provider.send("hardhat_setBalance", [
      buyer.address,
      ethers.utils.parseEther("400").toHexString().replace("0x0", "0x"),
    ]);

    bayc = await ethers.getContractAt("IERC721", BAYC);
  });

  it("Should be able to handle LooksRare/OpenSea trades together", async function () {
    const orderOne = getFixture("seaport", "bayc-2518-order.json");
    const orderTwo = getFixture("seaport", "bayc-8498-order.json");

    const seaportAbi = await getAbi("SeaportInterface.json");
    const seaportInterface = new ethers.utils.Interface(seaportAbi);

    const calldata = seaportInterface.encodeFunctionData("fulfillAvailableAdvancedOrders", [
      [orderOne, orderTwo],
      [],
      SEAPORT_OFFER_FULFILLMENT_TWO_ITEMS,
      SEAPORT_CONSIDERATION_FULFILLMENTS_TWO_ORDERS_SAME_COLLECTION,
      FULFILLER_CONDUIT_KEY,
      buyer.address,
      2,
    ]);

    const price = ethers.utils.parseEther("84");

    const tokenIdOne = 4251;
    const tokenIdTwo = 6026;

    const minPercentageToAsk = 9550;

    const takerBid = {
      isOrderAsk: false,
      taker: proxy.address,
      price,
      minPercentageToAsk,
      params: "0x",
    };

    // eslint-disable-next-line node/no-unsupported-features/es-syntax
    const takerBidOne = { ...takerBid, tokenId: tokenIdOne };
    // eslint-disable-next-line node/no-unsupported-features/es-syntax
    const takerBidTwo = { ...takerBid, tokenId: tokenIdTwo };

    const signatureOne =
      "0xc34d0d9cd04a7004e5d5838c75f4d53860cbd44287beac0bdd513245d6818f6e5d4c0bbce5ce1eb7dba919e277733c1b59f08fed99385d6bc6bc1af053f39fb001";
    const expandedSignatureOne = ethers.utils.splitSignature(signatureOne);

    const makerAsk = {
      isOrderAsk: true,
      collection: BAYC,
      price,
      amount: 1,
      strategy: LOOKSRARE_STRATEGY_FIXED_PRICE,
      currency: WETH,
      minPercentageToAsk,
      params: "0x",
    };

    const makerAskOne = {
      // eslint-disable-next-line node/no-unsupported-features/es-syntax
      ...makerAsk,
      signer: "0xe51416eF43f4820Aaa2b36ddD9CfE1278106190f",
      tokenId: tokenIdOne,
      nonce: 209,
      startTime: 1659529911,
      endTime: 1662121755,
      v: expandedSignatureOne.v,
      r: expandedSignatureOne.r,
      s: expandedSignatureOne.s,
    };

    const signatureTwo =
      "0x177d460a74c0adef0b4f83ec0588a8bca3bc36661828d3db6939d41333013aa211b1702fb648e7e11ba5354883aa7add92219ff907d8886b2cb0b45a81b1d2d601";
    const expandedSignatureTwo = ethers.utils.splitSignature(signatureTwo);

    const makerAskTwo = {
      // eslint-disable-next-line node/no-unsupported-features/es-syntax
      ...makerAsk,
      signer: "0xB1Ef9318e27116ca1d97466FEf76ba66496dd558",
      tokenId: tokenIdTwo,
      nonce: 1,
      startTime: 1659977872,
      endTime: 1660064095,
      v: expandedSignatureTwo.v,
      r: expandedSignatureTwo.r,
      s: expandedSignatureTwo.s,
    };

    const looksRareAbi = await getAbi("V0LooksRareProxy.json");
    const iface = new ethers.utils.Interface(looksRareAbi);

    const calldataLooksRare = iface.encodeFunctionData("execute", [
      [takerBidOne, takerBidTwo],
      [makerAskOne, makerAskTwo],
      buyer.address,
    ]);

    const seaportPrice = ethers.utils.parseEther("168.78");
    const looksRarePrice = ethers.utils.parseEther("168");
    const tx = await aggregator.connect(buyer).execute(
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
