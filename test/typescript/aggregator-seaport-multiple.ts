// import { expect } from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";
import { BAYC, SEAPORT } from "../constants";
import * as fs from "fs";
import * as path from "path";

describe("Aggregator", () => {
  let aggregator: Contract;
  let bayc: Contract;
  let buyer: SignerWithAddress;

  beforeEach(async () => {
    const Aggregator = await ethers.getContractFactory("Aggregator");
    aggregator = await Aggregator.deploy();
    await aggregator.deployed();

    // Seaport 1.1 fulfillAvailableAdvancedOrders
    await aggregator.addFunction(SEAPORT, "0x87201b41");

    [buyer] = await ethers.getSigners();

    await ethers.provider.send("hardhat_setBalance", [
      buyer.address,
      ethers.utils.parseEther("200").toHexString().replace("0x0", "0x"),
    ]);

    bayc = await ethers.getContractAt("IERC721", BAYC);
  });

  it("Should be able to handle OpenSea trades (fulfillAvailableOrders)", async function () {
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

    const abi = JSON.parse(
      await fs.readFileSync(path.join(__dirname, "../../abis/SeaportInterface.json"), { encoding: "utf8", flag: "r" })
    );
    const seaportInterface = new ethers.utils.Interface(abi);

    const fulfillerConduitKey = "0x0000000000000000000000000000000000000000000000000000000000000000";

    const calldata = seaportInterface.encodeFunctionData("fulfillAvailableAdvancedOrders", [
      [orderOne, orderTwo],
      [],
      offerFulfillments,
      considerationFulfillments,
      fulfillerConduitKey,
      buyer.address,
      2,
    ]);

    const price = ethers.utils.parseEther("168.78");
    const tx = await aggregator
      .connect(buyer)
      .buyWithETH([{ proxy: SEAPORT, data: calldata, value: price }], { value: price });

    await tx.wait();

    expect(await bayc.balanceOf(buyer.address)).to.equal(2);
    expect(await bayc.ownerOf(2518)).to.equal(buyer.address);
    expect(await bayc.ownerOf(8498)).to.equal(buyer.address);
  });
});
