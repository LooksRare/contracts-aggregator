import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";
import {
  BAYC,
  FULFILLER_CONDUIT_KEY,
  SEAPORT,
  SEAPORT_CONSIDERATION_FULFILLMENTS_TWO_ORDERS_SAME_COLLECTION,
  SEAPORT_OFFER_FULFILLMENT_TWO_ITEMS,
} from "../../constants";
import getAbi from "../utils/get-abi";
import getFixture from "../utils/get-fixture";
import getSignature from "../utils/get-signature";

describe("Aggregator", () => {
  let aggregator: Contract;
  let bayc: Contract;
  let buyer: SignerWithAddress;

  beforeEach(async () => {
    const Aggregator = await ethers.getContractFactory("V0Aggregator");
    aggregator = await Aggregator.deploy();
    await aggregator.deployed();

    const functionSelector = getSignature("SeaportInterface.json", "fulfillAvailableAdvancedOrders");
    await aggregator.addFunction(SEAPORT, functionSelector);

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

  it("Should be able to handle OpenSea trades (fulfillAvailableOrders)", async function () {
    const orderOne = getFixture("seaport", "bayc-2518-order.json");
    const orderTwo = getFixture("seaport", "bayc-8498-order.json");

    const abi = await getAbi("SeaportInterface.json");
    const seaportInterface = new ethers.utils.Interface(abi);

    const calldata = seaportInterface.encodeFunctionData("fulfillAvailableAdvancedOrders", [
      [orderOne, orderTwo],
      [],
      SEAPORT_OFFER_FULFILLMENT_TWO_ITEMS,
      SEAPORT_CONSIDERATION_FULFILLMENTS_TWO_ORDERS_SAME_COLLECTION,
      FULFILLER_CONDUIT_KEY,
      buyer.address,
      2,
    ]);

    const price = ethers.utils.parseEther("168.78");
    const tx = await aggregator
      .connect(buyer)
      .execute([{ proxy: SEAPORT, data: calldata, value: price }], { value: price });

    await tx.wait();

    expect(await bayc.balanceOf(buyer.address)).to.equal(2);
    expect(await bayc.ownerOf(2518)).to.equal(buyer.address);
    expect(await bayc.ownerOf(8498)).to.equal(buyer.address);
  });
});
