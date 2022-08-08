// import { expect } from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";
import { BAYC, FULFILLER_CONDUIT_KEY, SEAPORT } from "../constants";
import * as fs from "fs";
import * as path from "path";
import getAbi from "./utils/get-abi";

describe("Aggregator", () => {
  let aggregator: Contract;
  let bayc: Contract;
  let buyer: SignerWithAddress;

  beforeEach(async () => {
    const Aggregator = await ethers.getContractFactory("Aggregator");
    aggregator = await Aggregator.deploy();
    await aggregator.deployed();

    // Seaport 1.1 fulfillAdvancedOrder
    await aggregator.addFunction(SEAPORT, "0xe7acab24");

    [buyer] = await ethers.getSigners();

    await ethers.provider.send("hardhat_setBalance", [
      buyer.address,
      ethers.utils.parseEther("200").toHexString().replace("0x0", "0x"),
    ]);

    bayc = await ethers.getContractAt("IERC721", BAYC);
  });

  it("Should be able to handle OpenSea trades (fulfillAdvancedOrder)", async function () {
    const advancedOrder = JSON.parse(
      await fs.readFileSync(path.join(__dirname, "./fixtures/bayc-2518-order.json"), { encoding: "utf8", flag: "r" })
    );

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
      .buyWithETH([{ proxy: SEAPORT, data: calldata, value: price }], { value: price });

    await tx.wait();

    expect(await bayc.balanceOf(buyer.address)).to.equal(1);
    expect(await bayc.ownerOf(2518)).to.equal(buyer.address);
  });
});
