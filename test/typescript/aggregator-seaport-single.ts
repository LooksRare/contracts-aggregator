// import { expect } from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";
import * as fs from "fs";
import * as path from "path";

describe("Aggregator", () => {
  let aggregator: Contract;
  let bayc: Contract;
  let buyer: SignerWithAddress;
  const seaport = "0x00000000006c3852cbef3e08e8df289169ede581";

  beforeEach(async () => {
    const Aggregator = await ethers.getContractFactory("Aggregator");
    aggregator = await Aggregator.deploy();
    await aggregator.deployed();

    // Seaport 1.1 fulfillAdvancedOrder
    await aggregator.addFunction(seaport, "0xe7acab24");

    [buyer] = await ethers.getSigners();

    await ethers.provider.send("hardhat_setBalance", [
      buyer.address,
      ethers.utils.parseEther("200").toHexString().replace("0x0", "0x"),
    ]);

    bayc = await ethers.getContractAt("IERC721", "0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d");
  });

  it("Should be able to handle OpenSea trades (fulfillAdvancedOrder)", async function () {
    const tokenId = "2518";
    const advancedOrder = {
      parameters: {
        offerer: "0x7a277cf6e2f3704425195caae4148848c29ff815",
        zone: "0x004C00500000aD104D7DBd00e3ae0A5C00560C00",
        offer: [
          {
            itemType: "2",
            token: bayc.address,
            identifierOrCriteria: tokenId,
            startAmount: "1",
            endAmount: "1",
          },
        ],
        consideration: [
          {
            itemType: "0",
            token: "0x0000000000000000000000000000000000000000",
            identifierOrCriteria: "0",
            startAmount: "79800000000000000000",
            endAmount: "79800000000000000000",
            recipient: "0x7a277cf6e2f3704425195caae4148848c29ff815",
          },
          {
            itemType: "0",
            token: "0x0000000000000000000000000000000000000000",
            identifierOrCriteria: "0",
            startAmount: "2100000000000000000",
            endAmount: "2100000000000000000",
            recipient: "0x8De9C5A032463C561423387a9648c5C7BCC5BC90",
          },
          {
            itemType: "0",
            token: "0x0000000000000000000000000000000000000000",
            identifierOrCriteria: "0",
            startAmount: "2100000000000000000",
            endAmount: "2100000000000000000",
            recipient: "0xA858DDc0445d8131daC4d1DE01f834ffcbA52Ef1",
          },
        ],
        orderType: 2,
        startTime: "1659797236",
        endTime: "1662475636",
        zoneHash: "0x0000000000000000000000000000000000000000000000000000000000000000",
        salt: "70769720963177607",
        conduitKey: "0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000",
        totalOriginalConsiderationItems: 3,
      },
      numerator: 1,
      denominator: 1,
      signature:
        "0x27deb8f1923b96693d8d5e1bf9304207e31b9cb49e588e8df5b3926b7547ba444afafe429fb2a17b4b97544d8383f3ad886fc15cab5a91382a56f9d65bb3dc231c",
      extraData: "0x",
    };

    const abi = JSON.parse(
      await fs.readFileSync(path.join(__dirname, "Seaport.json"), { encoding: "utf8", flag: "r" })
    );
    const seaportInterface = new ethers.utils.Interface(abi);

    const fulfillerConduitKey = "0x0000000000000000000000000000000000000000000000000000000000000000";

    const calldata = seaportInterface.encodeFunctionData("fulfillAdvancedOrder", [
      advancedOrder,
      [],
      fulfillerConduitKey,
      buyer.address,
    ]);

    const price = ethers.utils.parseEther("84");
    const tx = await aggregator
      .connect(buyer)
      .buyWithETH([{ proxy: seaport, data: calldata, value: price }], { value: price });

    await tx.wait();

    expect(await bayc.balanceOf(buyer.address)).to.equal(1);
    expect(await bayc.ownerOf(tokenId)).to.equal(buyer.address);
  });
});
