import { expect } from "chai";
import { ethers } from "hardhat";
import { SEAPORT_EXTRA_DATA_SCHEMA } from "../constants";
import getFixture from "./utils/get-fixture";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import deploySeaportFixture from "./fixtures/deploy-seaport-fixture";
import getSeaportOrderExtraData from "./utils/get-seaport-order-extra-data";
import getSeaportOrderJson from "./utils/get-seaport-order-json";
import combineConsiderationAmount from "./utils/combine-consideration-amount";

describe("Aggregator", () => {
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
    // royalty one
    [{ orderIndex: 0, itemIndex: 2 }],
    // royalty two
    [{ orderIndex: 1, itemIndex: 2 }],
  ];

  it("Should be able to handle multiple collections and multiple collection types", async function () {
    const { aggregator, buyer, proxy, functionSelector, bayc, cityDao } = await loadFixture(deploySeaportFixture);

    const cityDaoOrders = getFixture("city-dao-orders.json");
    const orderOne = getFixture("bayc-6092-order.json");
    const orderTwo = cityDaoOrders[1].protocol_data;

    const priceOne = combineConsiderationAmount(orderOne.parameters.consideration);
    const priceTwo = combineConsiderationAmount(orderTwo.parameters.consideration);
    const price = priceOne.add(priceTwo);

    const abiCoder = ethers.utils.defaultAbiCoder;
    const tradeData = [
      {
        proxy: proxy.address,
        selector: functionSelector,
        value: price,
        orders: [
          getSeaportOrderJson(orderOne, priceOne, buyer.address),
          getSeaportOrderJson(orderTwo, priceTwo, buyer.address),
        ],
        ordersExtraData: [getSeaportOrderExtraData(orderOne), getSeaportOrderExtraData(orderTwo)],
        extraData: abiCoder.encode([SEAPORT_EXTRA_DATA_SCHEMA], [{ offerFulfillments, considerationFulfillments }]),
      },
    ];

    const tx = await aggregator.connect(buyer).buyWithETH(tradeData, { value: price });
    await tx.wait();

    expect(await bayc.balanceOf(buyer.address)).to.equal(1);
    expect(await cityDao.balanceOf(buyer.address, 42)).to.equal(1);
    expect(await bayc.ownerOf(6092)).to.equal(buyer.address);
  });
});
