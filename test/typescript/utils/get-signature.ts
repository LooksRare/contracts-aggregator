import getAbi from "./get-abi";
import { ethers } from "hardhat";

export default async function (file: string, selector: string): Promise<string> {
  const abi = await getAbi(file);
  const iface = new ethers.utils.Interface(abi);
  const fragment = iface.getFunction(selector);
  return iface.getSighash(fragment);
}
