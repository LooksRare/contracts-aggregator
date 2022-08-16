import { expect } from "chai";
import { ethers } from "hardhat";
import {
  BAYC,
  LOOKSRARE_EXTRA_DATA_SCHEMA,
  LOOKSRARE_STRATEGY_FIXED_PRICE,
  SEAPORT_EXTRA_DATA_SCHEMA,
  SEAPORT_CONSIDERATION_FULFILLMENTS_ONE_ORDER,
  WETH,
  SEAPORT_OFFER_FULFILLMENT_ONE_ITEM,
} from "../constants";
import getFixture from "./utils/get-fixture";
import getSeaportOrderExtraData from "./utils/get-seaport-order-extra-data";
import getSeaportOrderJson from "./utils/get-seaport-order-json";
import combineConsiderationAmount from "./utils/combine-consideration-amount";

import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import deployMultipleMarketFixtures from "./fixtures/deploy-multple-markets-fixture";

describe("Aggregator", () => {
  it("Should be able to handle trades from multiple markets", async function () {
    const { AddressZero, HashZero } = ethers.constants;
    const {
      aggregator,
      buyer,
      looksRareProxy,
      looksRareFunctionSelector,
      seaportProxy,
      seaportFunctionSelector,
      sudoswapProxy,
      sudoswapFunctionSelector,
      bayc,
    } = await loadFixture(deployMultipleMarketFixtures);
    const sudoswapPair = await ethers.getContractAt("ISudoswapPair", "0xc44b755cb278b682de1Cb07c7B3D15C44be62c34");
    const sudoswapQuote = await sudoswapPair.getBuyNFTQuote(1);

    const seaportOrder = getFixture("seaport", "bayc-6092-order.json");

    const seaportPrice = combineConsiderationAmount(seaportOrder.parameters.consideration);
    const looksRarePrice = ethers.utils.parseEther("78.69");
    const sudoswapPrice = sudoswapQuote[3];
    const price = seaportPrice.add(looksRarePrice).add(sudoswapPrice);

    const abiCoder = ethers.utils.defaultAbiCoder;
    const tradeData = [
      {
        proxy: seaportProxy.address,
        selector: seaportFunctionSelector,
        value: seaportPrice,
        orders: [getSeaportOrderJson(seaportOrder, seaportPrice, buyer.address)],
        ordersExtraData: [getSeaportOrderExtraData(seaportOrder)],
        extraData: abiCoder.encode(
          [SEAPORT_EXTRA_DATA_SCHEMA],
          [
            {
              offerFulfillments: SEAPORT_OFFER_FULFILLMENT_ONE_ITEM,
              considerationFulfillments: SEAPORT_CONSIDERATION_FULFILLMENTS_ONE_ORDER,
            },
          ]
        ),
      },
      {
        proxy: looksRareProxy.address,
        selector: looksRareFunctionSelector,
        value: looksRarePrice,
        orders: [
          {
            signer: "0xCd46DEe6e832e3ffa3FdC394b8dC673D6CA843dd",
            recipient: buyer.address,
            collection: BAYC,
            collectionType: 0,
            tokenIds: [2491],
            amounts: [1],
            price: looksRarePrice,
            currency: WETH,
            startTime: 1660231310,
            endTime: 1668007269,
            signature:
              "0x7b37474f79837ee4e56faf1e766a30a9d9c6ed3a7984457bcb212381f2b6b8f95a641ec95eca31f060a15a3c9ff2d4fbccbf481c766e8630be72b6e3e3aeca561b",
          },
        ],
        ordersExtraData: [abiCoder.encode(LOOKSRARE_EXTRA_DATA_SCHEMA, [LOOKSRARE_STRATEGY_FIXED_PRICE, 0, 9550])],
        extraData: "0x",
      },
      {
        proxy: sudoswapProxy.address,
        selector: sudoswapFunctionSelector,
        value: sudoswapPrice,
        orders: [
          {
            signer: AddressZero,
            recipient: buyer.address,
            collection: "0xc44b755cb278b682de1Cb07c7B3D15C44be62c34",
            collectionType: 0,
            tokenIds: [8167],
            amounts: [1],
            price: sudoswapPrice,
            currency: AddressZero,
            startTime: 0,
            endTime: 0,
            signature: HashZero,
          },
        ],
        ordersExtraData: [HashZero, HashZero],
        extraData: HashZero,
      },
    ];

    const tx = await aggregator.connect(buyer).buyWithETH(tradeData, false, { value: price });
    await tx.wait();

    expect(await bayc.balanceOf(buyer.address)).to.equal(3);
    expect(await bayc.ownerOf(6092)).to.equal(buyer.address);
    expect(await bayc.ownerOf(2491)).to.equal(buyer.address);
    expect(await bayc.ownerOf(8167)).to.equal(buyer.address);
  });
});
