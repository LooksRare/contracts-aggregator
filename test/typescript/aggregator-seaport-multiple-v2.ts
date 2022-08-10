import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, Contract } from "ethers";
import { ethers } from "hardhat";
import { BAYC } from "../constants";
import getFixture from "./utils/get-fixture";
import getSignature from "./utils/get-signature";

describe("Aggregator", () => {
  let aggregator: Contract;
  let proxy: Contract;
  let bayc: Contract;
  let buyer: SignerWithAddress;
  let functionSelector: string;
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

  beforeEach(async () => {
    const Aggregator = await ethers.getContractFactory("LooksRareAggregator");
    aggregator = await Aggregator.deploy();
    await aggregator.deployed();

    const SeaportProxy = await ethers.getContractFactory("SeaportProxy");
    proxy = await SeaportProxy.deploy();
    await proxy.deployed();

    functionSelector = await getSignature("SeaportProxy.json", "buyWithETH");
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

  const getOrderExtraData = (order: any): string => {
    const abiCoder = ethers.utils.defaultAbiCoder;
    return abiCoder.encode(orderExtraDataSchema, [
      {
        orderType: order.parameters.orderType,
        zone: order.parameters.zone,
        zoneHash: order.parameters.zoneHash,
        salt: order.parameters.salt,
        conduitKey: order.parameters.conduitKey,
        recipients: order.parameters.consideration.map((item: any) => ({
          recipient: item.recipient,
          amount: item.endAmount,
        })),
      },
    ]);
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
    const tradeData = [
      {
        proxy: proxy.address,
        selector: functionSelector,
        value: price,
        orders: [getOrderJson(orderOne, priceOne, buyer.address), getOrderJson(orderTwo, priceTwo, buyer.address)],
        ordersExtraData: [getOrderExtraData(orderOne), getOrderExtraData(orderTwo)],
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
