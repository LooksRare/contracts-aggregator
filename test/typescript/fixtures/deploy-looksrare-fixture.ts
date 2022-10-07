import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { LooksRareAggregator, LooksRareProxy } from "../../../typechain";
import getSignature from "../utils/get-signature";
import { BAYC, LOOKSRARE_V1 } from "../../constants";
import { Contract } from "ethers";

interface LooksRareFixture {
  aggregator: LooksRareAggregator;
  proxy: LooksRareProxy;
  buyer: SignerWithAddress;
  functionSelector: string;
  bayc: Contract;
}

export default async function deployLooksRareFixture(): Promise<LooksRareFixture> {
  const Aggregator = await ethers.getContractFactory("LooksRareAggregator");
  const aggregator = await Aggregator.deploy();
  await aggregator.deployed();

  const LooksRareProxy = await ethers.getContractFactory("LooksRareProxy");
  const proxy = await LooksRareProxy.deploy(LOOKSRARE_V1, aggregator.address);
  await proxy.deployed();

  // Because we are forking from the mainnet, the aggregator/proxy address might have a nonzero
  // balance, causing our test (balance comparison) to fail.
  await ethers.provider.send("hardhat_setBalance", [proxy.address, "0x0"]);
  await ethers.provider.send("hardhat_setBalance", [aggregator.address, "0x0"]);

  const functionSelector = await getSignature("LooksRareProxy.json", "execute");
  await aggregator.addFunction(proxy.address, functionSelector);

  const [, , buyer] = await ethers.getSigners();

  await ethers.provider.send("hardhat_setBalance", [
    buyer.address,
    ethers.utils.parseEther("200").toHexString().replace("0x0", "0x"),
  ]);

  const bayc = await ethers.getContractAt(
    "@looksrare/contracts-libs/contracts/interfaces/generic/IERC721.sol:IERC721",
    BAYC
  );

  return { aggregator, proxy, functionSelector, buyer, bayc };
}
