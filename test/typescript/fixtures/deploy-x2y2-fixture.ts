import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";
import { ethers } from "hardhat";
import { LooksRareAggregator, X2Y2Proxy } from "../../../typechain";
import { BAYC, PARALLEL, X2Y2 } from "../../constants";
import getSignature from "../utils/get-signature";

interface X2Y2Fixture {
  aggregator: LooksRareAggregator;
  functionSelector: string;
  proxy: X2Y2Proxy;
  buyer: SignerWithAddress;
  bayc: Contract;
  parallel: Contract;
}

export default async function deployX2Y2Fixture(): Promise<X2Y2Fixture> {
  const { send, getCode } = ethers.provider;

  const Aggregator = await ethers.getContractFactory("LooksRareAggregator");
  const aggregatorPlaceholder = await Aggregator.deploy();
  await aggregatorPlaceholder.deployed();

  const [owner, predefinedAggregator, buyer] = await ethers.getSigners();

  const aggregatorCode = await getCode(aggregatorPlaceholder.address);

  await send("hardhat_setCode", [predefinedAggregator.address, aggregatorCode]);

  const functionSelector = await getSignature("X2Y2Proxy.json", "execute");

  const aggregator = Aggregator.attach(predefinedAggregator.address);
  await send("hardhat_setStorageAt", [aggregator.address, "0x0", ethers.utils.hexZeroPad(owner.address, 32)]);

  const X2Y2Proxy = await ethers.getContractFactory("X2Y2Proxy");
  const proxy = await X2Y2Proxy.deploy(X2Y2, aggregator.address);
  await proxy.deployed();

  await aggregator.addFunction(proxy.address, functionSelector);

  // Because we are forking from the mainnet, the aggregator/proxy address might have a nonzero
  // balance, causing our test (balance comparison) to fail.
  await ethers.provider.send("hardhat_setBalance", [proxy.address, "0x0"]);
  await ethers.provider.send("hardhat_setBalance", [aggregator.address, "0x0"]);

  const buyerBalance = ethers.utils.parseEther("200").toHexString().replace("0x0", "0x");
  await send("hardhat_setBalance", [buyer.address, buyerBalance]);

  const bayc = await ethers.getContractAt("@openzeppelin/contracts/token/ERC721/IERC721.sol:IERC721", BAYC);
  const parallel = await ethers.getContractAt("@openzeppelin/contracts/token/ERC1155/IERC1155.sol:IERC1155", PARALLEL);

  return { aggregator, functionSelector, proxy, buyer, bayc, parallel };
}
