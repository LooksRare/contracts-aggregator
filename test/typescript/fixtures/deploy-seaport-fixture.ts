import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { IERC1155, IERC721, LooksRareAggregator, SeaportProxy } from "../../../typechain";
import getSignature from "../utils/get-signature";
import { BAYC, CITY_DAO, SEAPORT, USDC } from "../../constants";

interface SeaportFixture {
  aggregator: LooksRareAggregator;
  proxy: SeaportProxy;
  buyer: SignerWithAddress;
  functionSelector: string;
  bayc: IERC721;
  cityDao: IERC1155;
}

export default async function deploySeaportFixture(): Promise<SeaportFixture> {
  const Aggregator = await ethers.getContractFactory("LooksRareAggregator");
  const aggregator = await Aggregator.deploy();
  await aggregator.deployed();

  const SeaportProxy = await ethers.getContractFactory("SeaportProxy");
  const proxy = await SeaportProxy.deploy(SEAPORT);
  await proxy.deployed();

  // Because we are forking from the mainnet, the aggregator/proxy address might have a nonzero
  // balance, causing our test (balance comparison) to fail.
  await ethers.provider.send("hardhat_setBalance", [proxy.address, "0x0"]);
  await ethers.provider.send("hardhat_setBalance", [aggregator.address, "0x0"]);

  const functionSelector = await getSignature("SeaportProxy.json", "execute");
  await aggregator.addFunction(proxy.address, functionSelector);
  await aggregator.approve(proxy.address, USDC);

  const [, , buyer] = await ethers.getSigners();

  await ethers.provider.send("hardhat_setBalance", [
    buyer.address,
    ethers.utils.parseEther("200").toHexString().replace("0x0", "0x"),
  ]);

  const bayc = await ethers.getContractAt("IERC721", BAYC);
  const cityDao = await ethers.getContractAt("IERC1155", CITY_DAO);

  return { aggregator, proxy, functionSelector, buyer, bayc, cityDao };
}
