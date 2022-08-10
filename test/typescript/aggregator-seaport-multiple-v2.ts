import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, Contract } from "ethers";
import { ethers, network } from "hardhat";
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

  afterEach(async () => {
    await network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            jsonRpcUrl: process.env.ETH_RPC_URL,
            blockNumber: Number(process.env.FORKED_BLOCK_NUMBER),
          },
        },
      ],
    });
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

    const tx = await aggregator
      .connect(buyer)
      .buyWithETH(tradeData, { value: price.add(ethers.utils.parseEther("1")) });
    await tx.wait();

    expect(await bayc.balanceOf(buyer.address)).to.equal(2);
    expect(await bayc.ownerOf(2518)).to.equal(buyer.address);
    expect(await bayc.ownerOf(8498)).to.equal(buyer.address);
  });

  it("is able to refund extra ETH paid", async function () {
    const orderOne = getFixture("bayc-2518-order.json");
    const orderTwo = getFixture("bayc-8498-order.json");

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

    const buyerBalanceBefore = await ethers.provider.getBalance(buyer.address);
    const oneEther = ethers.utils.parseEther("1");

    const tx = await aggregator.connect(buyer).buyWithETH(tradeData, { value: price.add(oneEther) });
    await tx.wait();
    const receipt = await ethers.provider.getTransactionReceipt(tx.hash);
    const gasUsed = receipt.gasUsed;
    const txFee = gasUsed.mul(tx.gasPrice);

    expect(await bayc.balanceOf(buyer.address)).to.equal(2);
    expect(await bayc.ownerOf(2518)).to.equal(buyer.address);
    expect(await bayc.ownerOf(8498)).to.equal(buyer.address);
    expect(await ethers.provider.getBalance(aggregator.address)).to.equal(0);
    const buyerBalanceAfter = await ethers.provider.getBalance(buyer.address);
    expect(buyerBalanceBefore.sub(buyerBalanceAfter).sub(txFee)).to.equal(price);
  });
});
