import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";
import { BAYC, FULFILLER_CONDUIT_KEY, SEAPORT } from "../../constants";
import getAbi from "../utils/get-abi";
import getSignature from "../utils/get-signature";
import getFixture from "../utils/get-fixture";

describe("Aggregator", () => {
  let aggregator: Contract;
  let bayc: Contract;
  let buyer: SignerWithAddress;

  beforeEach(async () => {
    const Aggregator = await ethers.getContractFactory("V0Aggregator");
    aggregator = await Aggregator.deploy();
    await aggregator.deployed();

    const functionSelector = getSignature("SeaportInterface.json", "fulfillAdvancedOrder");
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

  it("Should be able to handle OpenSea trades (fulfillAdvancedOrder)", async function () {
    const advancedOrder = getFixture("seaport", "bayc-2518-order.json");

    const abi = await getAbi("SeaportInterface.json");
    const seaportInterface = new ethers.utils.Interface(abi);

    const calldata = seaportInterface.encodeFunctionData("fulfillAdvancedOrder", [
      advancedOrder,
      [],
      FULFILLER_CONDUIT_KEY,
      buyer.address,
    ]);

    const price = ethers.utils.parseEther("84");
    const tx = await aggregator
      .connect(buyer)
      .execute([{ proxy: SEAPORT, data: calldata, value: price }], { value: price });

    await tx.wait();

    expect(await bayc.balanceOf(buyer.address)).to.equal(1);
    expect(await bayc.ownerOf(2518)).to.equal(buyer.address);
  });
});
