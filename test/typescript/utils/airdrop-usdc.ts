import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import { USDC, USDC_WHALE } from "../../constants";

export default async function airdropUSDC(recipient: string, amount: BigNumber): Promise<void> {
  await ethers.provider.send("hardhat_impersonateAccount", [USDC_WHALE]);
  const ftx = await ethers.getSigner(USDC_WHALE);
  const usdc = await ethers.getContractAt("IERC20", USDC);
  await usdc.connect(ftx).transfer(recipient, amount);
  await ethers.provider.send("hardhat_stopImpersonatingAccount", [USDC_WHALE]);
}
