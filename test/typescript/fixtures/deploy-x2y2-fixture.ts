import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { IERC1155, IERC721, LooksRareAggregator, X2Y2Proxy } from "../../../typechain";
import { BAYC, PARALLEL, X2Y2 } from "../../constants";
import getSignature from "../utils/get-signature";

interface X2Y2Fixture {
  aggregator: LooksRareAggregator;
  functionSelector: string;
  proxy: X2Y2Proxy;
  buyer: SignerWithAddress;
  bayc: IERC721;
  parallel: IERC1155;
}

export default async function deployX2Y2Fixture(): Promise<X2Y2Fixture> {
  const Aggregator = await ethers.getContractFactory("LooksRareAggregator");
  const aggregator = await Aggregator.deploy();
  await aggregator.deployed();

  const X2Y2Proxy = await ethers.getContractFactory("X2Y2Proxy");
  const proxyPlaceholder = await X2Y2Proxy.deploy(X2Y2);
  await proxyPlaceholder.deployed();

  const [buyer, predefinedProxy] = await ethers.getSigners();

  const proxyCode = await ethers.provider.getCode(proxyPlaceholder.address);

  await ethers.provider.send("hardhat_setCode", [predefinedProxy.address, proxyCode]);

  const functionSelector = await getSignature("X2Y2Proxy.json", "buyWithETH");
  await aggregator.addFunction(predefinedProxy.address, functionSelector);

  const proxy = X2Y2Proxy.attach(predefinedProxy.address);
  await ethers.provider.send("hardhat_setStorageAt", [proxy.address, "0x0", ethers.utils.hexZeroPad(X2Y2, 32)]);

  // Because we are forking from the mainnet, the proxy address somehow already had a contract deployed to
  // the same address with ether balance, causing our test (balance comparison) to fail.
  await ethers.provider.send("hardhat_setBalance", [proxy.address, "0x0"]);

  await ethers.provider.send("hardhat_setBalance", [
    buyer.address,
    ethers.utils.parseEther("200").toHexString().replace("0x0", "0x"),
  ]);

  const bayc = await ethers.getContractAt("IERC721", BAYC);
  const parallel = await ethers.getContractAt("IERC1155", PARALLEL);

  return { aggregator, functionSelector, proxy, buyer, bayc, parallel };
}
