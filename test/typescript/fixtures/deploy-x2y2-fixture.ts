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

  // We need to copy the aggregator code to a pre-defined address because
  // we used that address to be the order taker when requesting X2Y2 to sign
  // the order.
  const aggregator = Aggregator.attach(predefinedAggregator.address);
  await send("hardhat_setStorageAt", [aggregator.address, "0x1", ethers.utils.hexZeroPad(owner.address, 32)]);

  const X2Y2Proxy = await ethers.getContractFactory("X2Y2Proxy");
  const proxy = await X2Y2Proxy.deploy(X2Y2, aggregator.address);
  await proxy.deployed();

  await aggregator.addFunction(proxy.address, functionSelector);

  // Because we are forking from the mainnet, the aggregator/proxy address might have a nonzero
  // balance, causing our test (balance comparison) to fail.
  await ethers.provider.send("hardhat_setBalance", [proxy.address, "0x0"]);
  await ethers.provider.send("hardhat_setBalance", [aggregator.address, "0x1"]);

  const buyerBalance = ethers.utils.parseEther("200").toHexString().replace("0x0", "0x");
  await send("hardhat_setBalance", [buyer.address, buyerBalance]);

  const bayc = await ethers.getContractAt(
    "@looksrare/contracts-libs/contracts/interfaces/generic/IERC721.sol:IERC721",
    BAYC
  );
  const parallel = await ethers.getContractAt(
    "@looksrare/contracts-libs/contracts/interfaces/generic/IERC1155.sol:IERC1155",
    PARALLEL
  );

  return { aggregator, functionSelector, proxy, buyer, bayc, parallel };
}
