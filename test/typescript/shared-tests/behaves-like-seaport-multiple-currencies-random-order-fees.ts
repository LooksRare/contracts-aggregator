import { ethers } from "hardhat";
import getFixture from "../utils/get-fixture";
import deploySeaportFixture from "../fixtures/deploy-seaport-fixture";
import combineConsiderationAmount from "../utils/combine-consideration-amount";
import getSeaportOrderJson, { OrderJson } from "../utils/get-seaport-order-json";
import getSeaportOrderExtraData from "../utils/get-seaport-order-extra-data";
import { SEAPORT, SEAPORT_EXTRA_DATA_SCHEMA, USDC } from "../../constants";
import validateSweepEvent from "../utils/validate-sweep-event";
import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import airdropUSDC from "../utils/airdrop-usdc";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber, Contract } from "ethers";

const encodedExtraData = (givenOrders: Array<string>): string => {
  const abiCoder = ethers.utils.defaultAbiCoder;
  let feesOne, feesTwo, royaltyOne, royaltyTwo;
  if (
    (givenOrders[0].match(/eth/) && givenOrders[1].match(/eth/)) ||
    (givenOrders[0].match(/usdc/) && givenOrders[1].match(/usdc/))
  ) {
    feesOne = [
      { orderIndex: 0, itemIndex: 1 },
      { orderIndex: 1, itemIndex: 1 },
    ];
    feesTwo = [
      { orderIndex: 2, itemIndex: 1 },
      { orderIndex: 3, itemIndex: 1 },
    ];
    royaltyOne = [
      { orderIndex: 0, itemIndex: 2 },
      { orderIndex: 1, itemIndex: 2 },
    ];
    royaltyTwo = [
      { orderIndex: 2, itemIndex: 2 },
      { orderIndex: 3, itemIndex: 2 },
    ];
  } else {
    feesOne = [
      { orderIndex: 0, itemIndex: 1 },
      { orderIndex: 2, itemIndex: 1 },
    ];
    feesTwo = [
      { orderIndex: 1, itemIndex: 1 },
      { orderIndex: 3, itemIndex: 1 },
    ];
    royaltyOne = [
      { orderIndex: 0, itemIndex: 2 },
      { orderIndex: 2, itemIndex: 2 },
    ];
    royaltyTwo = [
      { orderIndex: 1, itemIndex: 2 },
      { orderIndex: 3, itemIndex: 2 },
    ];
  }

  return abiCoder.encode(
    [SEAPORT_EXTRA_DATA_SCHEMA],
    [
      {
        offerFulfillments: [
          [{ orderIndex: 0, itemIndex: 0 }],
          [{ orderIndex: 1, itemIndex: 0 }],
          [{ orderIndex: 2, itemIndex: 0 }],
          [{ orderIndex: 3, itemIndex: 0 }],
        ],
        considerationFulfillments: [
          // seller one
          [{ orderIndex: 0, itemIndex: 0 }],
          // seller two
          [{ orderIndex: 1, itemIndex: 0 }],
          // seller three
          [{ orderIndex: 2, itemIndex: 0 }],
          // seller four
          [{ orderIndex: 3, itemIndex: 0 }],
          // OpenSea: Fees
          feesOne,
          feesTwo,
          // royalty
          royaltyOne,
          royaltyTwo,
        ],
      },
    ]
  );
};

export default function behavesLikeSeaportMultipleCurrenciesRandomOrderFees(isAtomic: boolean): void {
  const setUp = async (
    aggregator: Contract,
    erc20EnabledLooksRareAggregator: Contract,
    proxy: Contract,
    buyer: SignerWithAddress,
    protocolFeeRecipient: SignerWithAddress,
    usdcAirdropAmount: BigNumber
  ): Promise<void> => {
    await aggregator.approve(SEAPORT, USDC);
    await aggregator.setFee(proxy.address, 250, protocolFeeRecipient.address);

    await airdropUSDC(buyer.address, usdcAirdropAmount);

    const usdc = await ethers.getContractAt("@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20", USDC);
    await usdc.connect(buyer).approve(erc20EnabledLooksRareAggregator.address, usdcAirdropAmount);
  };

  const usdcOrders = () => {
    return [getFixture("seaport", "bayc-9948-order.json"), getFixture("seaport", "bayc-8350-order.json")];
  };

  const ethOrders = () => {
    return [getFixture("seaport", "bayc-9357-order.json"), getFixture("seaport", "bayc-9477-order.json")];
  };

  const priceAfterFee = (priceBeforeFee: BigNumber) => priceBeforeFee.mul(10250).div(10000);

  const priceInETHBeforeFees = () => {
    const ethPriceOneBeforeFee = combineConsiderationAmount(ethOrders()[0].parameters.consideration);
    const ethPriceTwoBeforeFee = combineConsiderationAmount(ethOrders()[1].parameters.consideration);
    return ethPriceOneBeforeFee.add(ethPriceTwoBeforeFee);
  };

  const priceInUSDCBeforeFees = () => {
    const usdcPriceOneBeforeFee = combineConsiderationAmount(usdcOrders()[0].parameters.consideration);
    const usdcPriceTwoBeforeFee = combineConsiderationAmount(usdcOrders()[1].parameters.consideration);
    return usdcPriceOneBeforeFee.add(usdcPriceTwoBeforeFee);
  };

  const priceInETH = () => priceAfterFee(priceInETHBeforeFees());
  const priceInUSDC = () => priceAfterFee(priceInUSDCBeforeFees());

  const ethFees = () => priceInETH().sub(priceInETHBeforeFees());
  const usdcFees = () => priceInUSDC().sub(priceInUSDCBeforeFees());

  const runTestInSpecificOrder = (givenOrders: Array<string>) => {
    it("Should be able to charge a fee", async function () {
      const { aggregator, erc20EnabledLooksRareAggregator, buyer, proxy, functionSelector, bayc } = await loadFixture(
        deploySeaportFixture
      );
      const { getBalance } = ethers.provider;

      const [, protocolFeeRecipient] = await ethers.getSigners();

      const [usdcOrderOne, usdcOrderTwo] = usdcOrders();
      const [ethOrderOne, ethOrderTwo] = ethOrders();

      await setUp(aggregator, erc20EnabledLooksRareAggregator, proxy, buyer, protocolFeeRecipient, priceInUSDC());

      const tokenTransfers = [{ amount: priceInUSDC(), currency: USDC }];

      /* eslint-disable prefer-const */
      let orders: Array<OrderJson> = [];
      let ordersExtraData: Array<string> = [];

      givenOrders.forEach((order: string) => {
        if (order === "ethOrderOne") {
          orders.push(getSeaportOrderJson(ethOrderOne));
          ordersExtraData.push(getSeaportOrderExtraData(ethOrderOne));
        } else if (order === "ethOrderTwo") {
          orders.push(getSeaportOrderJson(ethOrderTwo));
          ordersExtraData.push(getSeaportOrderExtraData(ethOrderTwo));
        } else if (order === "usdcOrderOne") {
          orders.push(getSeaportOrderJson(usdcOrderOne));
          ordersExtraData.push(getSeaportOrderExtraData(usdcOrderOne));
        } else if (order === "usdcOrderTwo") {
          orders.push(getSeaportOrderJson(usdcOrderTwo));
          ordersExtraData.push(getSeaportOrderExtraData(usdcOrderTwo));
        }
      });

      const tradeData = [
        {
          proxy: proxy.address,
          selector: functionSelector,
          value: priceInETH(),
          orders,
          ordersExtraData,
          extraData: isAtomic ? encodedExtraData(givenOrders) : ethers.constants.HashZero,
          tokenTransfers,
        },
      ];

      const usdc = await ethers.getContractAt("@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20", USDC);

      const feeRecipientUSDCBalanceBefore = await usdc.balanceOf(protocolFeeRecipient.address);
      const feeRecipientEthBalanceBefore = await getBalance(protocolFeeRecipient.address);

      const tx = await erc20EnabledLooksRareAggregator
        .connect(buyer)
        .execute(tokenTransfers, tradeData, buyer.address, isAtomic, { value: priceInETH() });
      const receipt = await tx.wait();

      const feeRecipientUSDCBalanceAfter = await usdc.balanceOf(protocolFeeRecipient.address);
      const feeRecipientEthBalanceAfter = await getBalance(protocolFeeRecipient.address);

      expect(feeRecipientUSDCBalanceAfter.sub(feeRecipientUSDCBalanceBefore)).to.equal(usdcFees());
      expect(feeRecipientEthBalanceAfter.sub(feeRecipientEthBalanceBefore)).to.equal(ethFees());

      validateSweepEvent(receipt, buyer.address);

      expect(await bayc.balanceOf(buyer.address)).to.equal(4);
      expect(await bayc.ownerOf(9948)).to.equal(buyer.address);
      expect(await bayc.ownerOf(8350)).to.equal(buyer.address);
      expect(await bayc.ownerOf(9357)).to.equal(buyer.address);
      expect(await bayc.ownerOf(9477)).to.equal(buyer.address);
    });
  };

  describe("Execution order: USDC - USDC - ETH - ETH", async function () {
    runTestInSpecificOrder(["usdcOrderOne", "usdcOrderTwo", "ethOrderOne", "ethOrderTwo"]);
  });

  describe("Execution order: ETH - ETH - USDC - USDC", async function () {
    runTestInSpecificOrder(["ethOrderOne", "ethOrderTwo", "usdcOrderOne", "usdcOrderTwo"]);
  });

  describe("Execution order: ETH - USDC - ETH - USDC", async function () {
    runTestInSpecificOrder(["ethOrderOne", "usdcOrderOne", "ethOrderTwo", "usdcOrderTwo"]);
  });

  describe("Execution order: USDC - ETH - USDC - ETH", async function () {
    runTestInSpecificOrder(["usdcOrderOne", "ethOrderOne", "usdcOrderTwo", "ethOrderTwo"]);
  });
}
