import { ethers } from "hardhat";
import getFixture from "../utils/get-fixture";
import deploySeaportFixture from "../fixtures/deploy-seaport-fixture";
import combineConsiderationAmount from "../utils/combine-consideration-amount";
import getSeaportOrderJson from "../utils/get-seaport-order-json";
import getSeaportOrderExtraData from "../utils/get-seaport-order-extra-data";
import { SEAPORT_EXTRA_DATA_SCHEMA, USDC } from "../../constants";
import validateSweepEvent from "../utils/validate-sweep-event";
import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import airdropUSDC from "../utils/airdrop-usdc";

const encodedExtraData = () => {
  const abiCoder = ethers.utils.defaultAbiCoder;
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
          [
            { orderIndex: 0, itemIndex: 1 },
            { orderIndex: 1, itemIndex: 1 },
          ],
          [
            { orderIndex: 2, itemIndex: 1 },
            { orderIndex: 3, itemIndex: 1 },
          ],
          // royalty
          [
            { orderIndex: 0, itemIndex: 2 },
            { orderIndex: 1, itemIndex: 2 },
          ],
          [
            { orderIndex: 2, itemIndex: 2 },
            { orderIndex: 3, itemIndex: 2 },
          ],
        ],
      },
    ]
  );
};

export default function behavesLikeSeaportMultipleCurrenciesRandomOrderFees(isAtomic: boolean): void {
  describe("Execution order: USDC - USDC - ETH - ETH", async function () {
    it("Should be able to charge a fee", async function () {
      const { aggregator, buyer, proxy, functionSelector, bayc } = await loadFixture(deploySeaportFixture);
      const { getBalance } = ethers.provider;

      const [, protocolFeeRecipient] = await ethers.getSigners();

      const orderOne = getFixture("seaport", "bayc-9948-order.json");
      const orderTwo = getFixture("seaport", "bayc-8350-order.json");

      const orderThree = getFixture("seaport", "bayc-9357-order.json");
      const orderFour = getFixture("seaport", "bayc-9477-order.json");

      // USDC
      const priceOneBeforeFee = combineConsiderationAmount(orderOne.parameters.consideration);
      const priceOne = priceOneBeforeFee.mul(10250).div(10000); // Fee
      const priceTwoBeforeFee = combineConsiderationAmount(orderTwo.parameters.consideration);
      const priceTwo = priceTwoBeforeFee.mul(10250).div(10000); // Fee
      const priceInUSDC = priceOne.add(priceTwo);

      // ETH
      const priceThreeBeforeFee = combineConsiderationAmount(orderThree.parameters.consideration);
      const priceThree = priceThreeBeforeFee.mul(10250).div(10000); // Fee
      const priceFourBeforeFee = combineConsiderationAmount(orderFour.parameters.consideration);
      const priceFour = priceFourBeforeFee.mul(10250).div(10000); // Fee
      const priceInETH = priceThree.add(priceFour);

      // Doesn't look good here but the buyer is the first address, meaning the contract deployer/owner
      await proxy.connect(buyer).approve(USDC);

      // Doesn't look good here but the buyer is the first address, meaning the contract deployer/owner
      await proxy.connect(buyer).setFeeBp(250);
      await proxy.connect(buyer).setFeeRecipient(protocolFeeRecipient.address);

      await airdropUSDC(buyer.address, priceInUSDC);

      const usdc = await ethers.getContractAt("IERC20", USDC);
      await usdc.connect(buyer).approve(aggregator.address, priceInUSDC);

      const tokenTransfers = [{ amount: priceInUSDC, currency: USDC }];

      const tradeData = [
        {
          proxy: proxy.address,
          selector: functionSelector,
          value: priceInETH,
          orders: [
            getSeaportOrderJson(orderOne, priceOneBeforeFee),
            getSeaportOrderJson(orderTwo, priceTwoBeforeFee),
            getSeaportOrderJson(orderThree, priceThreeBeforeFee),
            getSeaportOrderJson(orderFour, priceFourBeforeFee),
          ],
          ordersExtraData: [
            getSeaportOrderExtraData(orderOne),
            getSeaportOrderExtraData(orderTwo),
            getSeaportOrderExtraData(orderThree),
            getSeaportOrderExtraData(orderFour),
          ],
          extraData: isAtomic ? encodedExtraData() : ethers.constants.HashZero,
          tokenTransfers,
        },
      ];

      const feeRecipientUSDCBalanceBefore = await usdc.balanceOf(protocolFeeRecipient.address);
      const feeRecipientEthBalanceBefore = await getBalance(protocolFeeRecipient.address);

      const tx = await aggregator
        .connect(buyer)
        .execute(tokenTransfers, tradeData, buyer.address, isAtomic, { value: priceInETH });
      const receipt = await tx.wait();

      const feeRecipientUSDCBalanceAfter = await usdc.balanceOf(protocolFeeRecipient.address);
      const feeRecipientEthBalanceAfter = await getBalance(protocolFeeRecipient.address);

      expect(feeRecipientUSDCBalanceAfter.sub(feeRecipientUSDCBalanceBefore)).to.equal(
        priceOne.sub(priceOneBeforeFee).add(priceTwo.sub(priceTwoBeforeFee))
      );
      expect(feeRecipientEthBalanceAfter.sub(feeRecipientEthBalanceBefore)).to.equal(
        priceThree.sub(priceThreeBeforeFee).add(priceFour.sub(priceFourBeforeFee))
      );

      validateSweepEvent(receipt, buyer.address, 1, 1);

      expect(await bayc.balanceOf(buyer.address)).to.equal(4);
      expect(await bayc.ownerOf(9948)).to.equal(buyer.address);
      expect(await bayc.ownerOf(8350)).to.equal(buyer.address);
      expect(await bayc.ownerOf(9357)).to.equal(buyer.address);
      expect(await bayc.ownerOf(9477)).to.equal(buyer.address);
    });
  });
}
