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
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber, Contract } from "ethers";

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
  const setUp = async (
    aggregator: Contract,
    proxy: Contract,
    buyer: SignerWithAddress,
    protocolFeeRecipient: SignerWithAddress,
    usdcAirdropAmount: BigNumber
  ): Promise<void> => {
    // Doesn't look good here but the buyer is the first address, meaning the contract deployer/owner
    await proxy.connect(buyer).approve(USDC);
    await proxy.connect(buyer).setFeeBp(250);
    await proxy.connect(buyer).setFeeRecipient(protocolFeeRecipient.address);

    await airdropUSDC(buyer.address, usdcAirdropAmount);

    const usdc = await ethers.getContractAt("IERC20", USDC);
    await usdc.connect(buyer).approve(aggregator.address, usdcAirdropAmount);
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

  const expectBAYCToHaveChangedHands = async (bayc: Contract, buyer: string): Promise<void> => {
    expect(await bayc.balanceOf(buyer)).to.equal(4);
    expect(await bayc.ownerOf(9948)).to.equal(buyer);
    expect(await bayc.ownerOf(8350)).to.equal(buyer);
    expect(await bayc.ownerOf(9357)).to.equal(buyer);
    expect(await bayc.ownerOf(9477)).to.equal(buyer);
  };

  describe("Execution order: USDC - USDC - ETH - ETH", async function () {
    it("Should be able to charge a fee", async function () {
      const { aggregator, buyer, proxy, functionSelector, bayc } = await loadFixture(deploySeaportFixture);
      const { getBalance } = ethers.provider;

      const [, protocolFeeRecipient] = await ethers.getSigners();

      const [usdcOrderOne, usdcOrderTwo] = usdcOrders();
      const [ethOrderOne, ethOrderTwo] = ethOrders();

      // USDC
      const usdcPriceOneBeforeFee = combineConsiderationAmount(usdcOrderOne.parameters.consideration);
      const usdcPriceTwoBeforeFee = combineConsiderationAmount(usdcOrderTwo.parameters.consideration);

      // ETH
      const ethPriceOneBeforeFee = combineConsiderationAmount(ethOrderOne.parameters.consideration);
      const ethPriceTwoBeforeFee = combineConsiderationAmount(ethOrderTwo.parameters.consideration);

      await setUp(aggregator, proxy, buyer, protocolFeeRecipient, priceInUSDC());

      const tokenTransfers = [{ amount: priceInUSDC(), currency: USDC }];

      const tradeData = [
        {
          proxy: proxy.address,
          selector: functionSelector,
          value: priceInETH(),
          orders: [
            getSeaportOrderJson(usdcOrderOne, usdcPriceOneBeforeFee),
            getSeaportOrderJson(usdcOrderTwo, usdcPriceTwoBeforeFee),
            getSeaportOrderJson(ethOrderOne, ethPriceOneBeforeFee),
            getSeaportOrderJson(ethOrderTwo, ethPriceTwoBeforeFee),
          ],
          ordersExtraData: [
            getSeaportOrderExtraData(usdcOrderOne),
            getSeaportOrderExtraData(usdcOrderTwo),
            getSeaportOrderExtraData(ethOrderOne),
            getSeaportOrderExtraData(ethOrderTwo),
          ],
          extraData: isAtomic ? encodedExtraData() : ethers.constants.HashZero,
          tokenTransfers,
        },
      ];

      const usdc = await ethers.getContractAt("IERC20", USDC);

      const feeRecipientUSDCBalanceBefore = await usdc.balanceOf(protocolFeeRecipient.address);
      const feeRecipientEthBalanceBefore = await getBalance(protocolFeeRecipient.address);

      const tx = await aggregator
        .connect(buyer)
        .execute(tokenTransfers, tradeData, buyer.address, isAtomic, { value: priceInETH() });
      const receipt = await tx.wait();

      const feeRecipientUSDCBalanceAfter = await usdc.balanceOf(protocolFeeRecipient.address);
      const feeRecipientEthBalanceAfter = await getBalance(protocolFeeRecipient.address);

      expect(feeRecipientUSDCBalanceAfter.sub(feeRecipientUSDCBalanceBefore)).to.equal(usdcFees());
      expect(feeRecipientEthBalanceAfter.sub(feeRecipientEthBalanceBefore)).to.equal(ethFees());

      validateSweepEvent(receipt, buyer.address, 1, 1);
      await expectBAYCToHaveChangedHands(bayc, buyer.address);
    });
  });
}
