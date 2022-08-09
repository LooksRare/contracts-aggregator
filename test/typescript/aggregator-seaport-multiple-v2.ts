import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, Contract } from "ethers";
import { ethers } from "hardhat";
import { BAYC } from "../constants";
import getAbi from "./utils/get-abi";
import getFixture from "./utils/get-fixture";

describe("Aggregator", () => {
  let aggregator: Contract;
  let proxy: Contract;
  let bayc: Contract;
  let buyer: SignerWithAddress;
  let functionSelector: string;

  beforeEach(async () => {
    const Aggregator = await ethers.getContractFactory("LooksRareAggregator");
    aggregator = await Aggregator.deploy();
    await aggregator.deployed();

    const SeaportProxy = await ethers.getContractFactory("SeaportProxy");
    proxy = await SeaportProxy.deploy();
    await proxy.deployed();

    const abi = await getAbi("SeaportProxy.json");
    const iface = new ethers.utils.Interface(abi);
    const fragment = iface.getFunction("buyWithETH");
    functionSelector = iface.getSighash(fragment);
    await aggregator.addFunction(proxy.address, functionSelector);

    [buyer] = await ethers.getSigners();

    await ethers.provider.send("hardhat_setBalance", [
      buyer.address,
      ethers.utils.parseEther("200").toHexString().replace("0x0", "0x"),
    ]);

    bayc = await ethers.getContractAt("IERC721", BAYC);
  });

  const combineConsiderationAmount = (consideration: Array<any>) =>
    consideration.reduce((sum: number, item: any) => BigNumber.from(item.endAmount).add(sum), 0);

  const getOrderJson = (listing: any, price: BigNumber, recipient: string) => {
    const order = {
      price,
      recipient,
      signer: listing.parameters.offerer,
      collection: listing.parameters.offer[0].token,
      tokenId: listing.parameters.offer[0].identifierOrCriteria,
      amount: 1,
      currency: listing.parameters.consideration[0].token,
      startTime: listing.parameters.startTime,
      endTime: listing.parameters.endTime,
      signature: listing.signature,
    };

    return order;
  };

  it("Should be able to handle OpenSea trades (fulfillAvailableAdvancedOrders)", async function () {
    const orderOne = getFixture("bayc-2518-order.json");
    const orderTwo = getFixture("bayc-8498-order.json");

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

    const priceOne = combineConsiderationAmount(orderOne.parameters.consideration);
    const priceTwo = combineConsiderationAmount(orderTwo.parameters.consideration);
    const price = priceOne.add(priceTwo);

    const abiCoder = ethers.utils.defaultAbiCoder;
    const extraDataSchema = [
      `
      tuple(
        tuple(uint256 orderIndex, uint256 itemIndex)[][] offerFulfillments,
        tuple(uint256 orderIndex, uint256 itemIndex)[][] considerationFulfillments
      )`,
    ];
    const orderExtraDataSchema = [
      `
      tuple(
        uint8 orderType,
        address zone,
        bytes32 zoneHash,
        uint256 salt,
        bytes32 conduitKey,
        tuple(address recipient, uint256 amount)[] recipients
      ) orderExtraData
      `,
    ];
    const tradeData = [
      {
        proxy: proxy.address,
        selector: functionSelector,
        value: price,
        orders: [getOrderJson(orderOne, priceOne, buyer.address), getOrderJson(orderTwo, priceTwo, buyer.address)],
        ordersExtraData: [
          abiCoder.encode(orderExtraDataSchema, [
            {
              orderType: orderOne.parameters.orderType,
              zone: orderOne.parameters.zone,
              zoneHash: orderOne.parameters.zoneHash,
              salt: orderOne.parameters.salt,
              conduitKey: orderOne.parameters.conduitKey,
              recipients: orderOne.parameters.consideration.map((item: any) => ({
                recipient: item.recipient,
                amount: item.endAmount,
              })),
            },
          ]),
          abiCoder.encode(orderExtraDataSchema, [
            {
              orderType: orderTwo.parameters.orderType,
              zone: orderTwo.parameters.zone,
              zoneHash: orderTwo.parameters.zoneHash,
              salt: orderTwo.parameters.salt,
              conduitKey: orderTwo.parameters.conduitKey,
              recipients: orderTwo.parameters.consideration.map((item: any) => ({
                recipient: item.recipient,
                amount: item.endAmount,
              })),
            },
          ]),
        ],
        extraData: abiCoder.encode(extraDataSchema, [{ offerFulfillments, considerationFulfillments }]),
      },
    ];

    const tx = await aggregator.connect(buyer).buyWithETH(tradeData, { value: price });
    await tx.wait();

    expect(await bayc.balanceOf(buyer.address)).to.equal(2);
    expect(await bayc.ownerOf(2518)).to.equal(buyer.address);
    expect(await bayc.ownerOf(8498)).to.equal(buyer.address);
  });
});
