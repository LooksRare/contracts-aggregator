import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { IERC721, LooksRareAggregator, LooksRareProxy, SeaportProxy, SudoswapProxy } from "../../../typechain";
import getSignature from "../utils/get-signature";
import { BAYC, LOOKSRARE_V1, SEAPORT, SUDOSWAP } from "../../constants";

interface MultipleMarketsFixture {
  aggregator: LooksRareAggregator;
  looksRareProxy: LooksRareProxy;
  looksRareFunctionSelector: string;
  seaportProxy: SeaportProxy;
  seaportFunctionSelector: string;
  sudoswapProxy: SudoswapProxy;
  sudoswapFunctionSelector: string;
  buyer: SignerWithAddress;
  bayc: IERC721;
}

export default async function deployLooksRareFixture(): Promise<MultipleMarketsFixture> {
  const Aggregator = await ethers.getContractFactory("LooksRareAggregator");
  const aggregator = await Aggregator.deploy();
  await aggregator.deployed();

  const LooksRareProxy = await ethers.getContractFactory("LooksRareProxy");
  const looksRareProxy = await LooksRareProxy.deploy(LOOKSRARE_V1);
  await looksRareProxy.deployed();

  const looksRareFunctionSelector = await getSignature("LooksRareProxy.json", "execute");
  await aggregator.addFunction(looksRareProxy.address, looksRareFunctionSelector);

  const SeaportProxy = await ethers.getContractFactory("SeaportProxy");
  const seaportProxy = await SeaportProxy.deploy(SEAPORT);
  await seaportProxy.deployed();

  const seaportFunctionSelector = await getSignature("SeaportProxy.json", "execute");
  await aggregator.addFunction(seaportProxy.address, seaportFunctionSelector);

  const SudoswapProxy = await ethers.getContractFactory("SudoswapProxy");
  const sudoswapProxy = await SudoswapProxy.deploy(SUDOSWAP);
  await sudoswapProxy.deployed();

  const sudoswapFunctionSelector = await getSignature("SudoswapProxy.json", "execute");
  await aggregator.addFunction(sudoswapProxy.address, sudoswapFunctionSelector);

  const [, , buyer] = await ethers.getSigners();

  // Because we are forking from the mainnet, the aggregator/proxy address might have a nonzero
  // balance, causing our test (balance comparison) to fail.
  await ethers.provider.send("hardhat_setBalance", [aggregator.address, "0x0"]);
  await ethers.provider.send("hardhat_setBalance", [looksRareProxy.address, "0x0"]);
  await ethers.provider.send("hardhat_setBalance", [seaportProxy.address, "0x0"]);
  await ethers.provider.send("hardhat_setBalance", [sudoswapProxy.address, "0x0"]);

  await ethers.provider.send("hardhat_setBalance", [
    buyer.address,
    ethers.utils.parseEther("600").toHexString().replace("0x0", "0x"),
  ]);

  const bayc = await ethers.getContractAt("IERC721", BAYC);

  return {
    aggregator,
    looksRareProxy,
    looksRareFunctionSelector,
    seaportProxy,
    seaportFunctionSelector,
    sudoswapProxy,
    sudoswapFunctionSelector,
    buyer,
    bayc,
  };
}
