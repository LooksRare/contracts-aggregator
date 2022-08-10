import { BigNumber } from "ethers";
import { ethers } from "hardhat";

export default async function calculateTxFee(tx: any): Promise<BigNumber> {
  const receipt = await ethers.provider.getTransactionReceipt(tx.hash);
  const gasUsed = receipt.gasUsed;
  return gasUsed.mul(tx.gasPrice);
}
