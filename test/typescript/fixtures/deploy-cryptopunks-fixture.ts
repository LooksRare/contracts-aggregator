import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { ICryptoPunks, LooksRareAggregator, CryptoPunksProxy } from "../../../typechain";
import { CRYPTOPUNKS } from "../../constants";
import getSignature from "../utils/get-signature";

interface CryptoPunksFixture {
  aggregator: LooksRareAggregator;
  functionSelector: string;
  proxy: CryptoPunksProxy;
  buyer: SignerWithAddress;
  cryptopunks: ICryptoPunks;
}

export default async function deployCryptoPunksFixture(): Promise<CryptoPunksFixture> {
  const Aggregator = await ethers.getContractFactory("LooksRareAggregator");
  const aggregator = await Aggregator.deploy();
  await aggregator.deployed();

  const CryptoPunksProxy = await ethers.getContractFactory("CryptoPunksProxy");
  const proxy = await CryptoPunksProxy.deploy(CRYPTOPUNKS);
  await proxy.deployed();

  const [buyer] = await ethers.getSigners();

  const functionSelector = await getSignature("CryptoPunksProxy.json", "execute");
  await aggregator.addFunction(proxy.address, functionSelector);

  // Because we are forking from the mainnet, the aggregator/proxy address might have a nonzero
  // balance, causing our test (balance comparison) to fail.
  await ethers.provider.send("hardhat_setBalance", [proxy.address, "0x0"]);
  await ethers.provider.send("hardhat_setBalance", [aggregator.address, "0x0"]);

  await ethers.provider.send("hardhat_setBalance", [
    buyer.address,
    ethers.utils.parseEther("300").toHexString().replace("0x0", "0x"),
  ]);

  const cryptopunks = await ethers.getContractAt("ICryptoPunks", CRYPTOPUNKS);

  return { aggregator, functionSelector, proxy, buyer, cryptopunks };
}
