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

    // Seaport 1.1 fulfillAvailableOrders
    await aggregator.addFunction(SEAPORT, "0xed98a574");

    [buyer] = await ethers.getSigners();

    await ethers.provider.send("hardhat_setBalance", [
      buyer.address,
      ethers.utils.parseEther("200").toHexString().replace("0x0", "0x"),
    ]);

    bayc = await ethers.getContractAt("IERC721", BAYC);
  });

  it("Should be able to handle OpenSea trades (fulfillAvailableOrders)", async function () {
    const tokenIdOne = "2518";
    const tokenIdTwo = "8498";

    const orderOne = {
      parameters: {
        offerer: "0x7a277cf6e2f3704425195caae4148848c29ff815",
        zone: "0x004C00500000aD104D7DBd00e3ae0A5C00560C00",
        offer: [
          {
            itemType: "2",
            token: bayc.address,
            identifierOrCriteria: tokenIdOne,
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

    const orderTwo = {
      parameters: {
        offerer: "0x72f1c8601c30c6f42ca8b0e85d1b2f87626a0deb",
        zone: "0x004C00500000aD104D7DBd00e3ae0A5C00560C00",
        offer: [
          {
            itemType: "2",
            token: bayc.address,
            identifierOrCriteria: tokenIdTwo,
            startAmount: "1",
            endAmount: "1",
          },
        ],
        consideration: [
          {
            itemType: 0,
            token: "0x0000000000000000000000000000000000000000",
            identifierOrCriteria: "0",
            startAmount: "80541000000000000000",
            endAmount: "80541000000000000000",
            recipient: "0x72F1C8601C30C6f42CA8b0E85D1b2F87626A0deb",
          },
          {
            itemType: 0,
            token: "0x0000000000000000000000000000000000000000",
            identifierOrCriteria: "0",
            startAmount: "2119500000000000000",
            endAmount: "2119500000000000000",
            recipient: "0x8De9C5A032463C561423387a9648c5C7BCC5BC90",
          },
          {
            itemType: 0,
            token: "0x0000000000000000000000000000000000000000",
            identifierOrCriteria: "0",
            startAmount: "2119500000000000000",
            endAmount: "2119500000000000000",
            recipient: "0xA858DDc0445d8131daC4d1DE01f834ffcbA52Ef1",
          },
        ],
        orderType: 2,
        startTime: "1659944298",
        endTime: "1662303030",
        zoneHash: "0x0000000000000000000000000000000000000000000000000000000000000000",
        salt: "90974057687252886",
        conduitKey: "0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000",
        totalOriginalConsiderationItems: 3,
      },
      numerator: 1,
      denominator: 1,
      signature:
        "0xfcdc82cba99c19522af3692070e4649ff573d20f2550eb29f7a24b3c39da74bd6a6c5b8444a2139c529301a8da011af414342d304609f896580e12fbd94d387a1b",
      extraData: "0x",
    };

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

    // function fulfillAvailableOrders(
    // struct Order[] orders,
    // struct FulfillmentComponent[][] offerFulfillments,
    // struct FulfillmentComponent[][] considerationFulfillments,
    // bytes32 fulfillerConduitKey,
    // uint256 maximumFulfilled) external payable returns (bool[] availableOrders, struct Execution[] executions)
    const calldata = seaportInterface.encodeFunctionData("fulfillAvailableOrders", [
      [orderOne, orderTwo],
      offerFulfillments,
      considerationFulfillments,
      fulfillerConduitKey,
      2,
    ]);

    const price = ethers.utils.parseEther("168.78");
    const tx = await aggregator
      .connect(buyer)
      .buyWithETH([{ proxy: SEAPORT, data: calldata, value: price }], { value: price });

    await tx.wait();

    // expect(await bayc.balanceOf(buyer.address)).to.equal(2);
    // expect(await bayc.ownerOf(tokenIdOne)).to.equal(buyer.address);
    // expect(await bayc.ownerOf(tokenIdTwo)).to.equal(buyer.address);
    expect(await bayc.balanceOf(aggregator.address)).to.equal(2);
    expect(await bayc.ownerOf(tokenIdOne)).to.equal(aggregator.address);
    expect(await bayc.ownerOf(tokenIdTwo)).to.equal(aggregator.address);
  });
});
