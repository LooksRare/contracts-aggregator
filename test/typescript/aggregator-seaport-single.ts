// import { expect } from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";

describe("Aggregator", () => {
  let aggregator: Contract;
  let bayc: Contract;
  let buyer: SignerWithAddress;

  beforeEach(async () => {
    const Aggregator = await ethers.getContractFactory("Aggregator");
    aggregator = await Aggregator.deploy();
    await aggregator.deployed();

    // Seaport 1.1 fulfillBasicOrder
    await aggregator.addFunction("0xfb0f3ee1", "0x00000000006c3852cbef3e08e8df289169ede581");

    [buyer] = await ethers.getSigners();

    await ethers.provider.send("hardhat_setBalance", [
      buyer.address,
      ethers.utils.parseEther("200").toHexString().replace("0x0", "0x"),
    ]);

    bayc = await ethers.getContractAt("IERC721", "0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d");
  });

  it("Should be able to handle OpenSea trades (fulfillBasicOrder)", async function () {
    const price = ethers.utils.parseEther("81.75");

    const basicOrderParameters = {
      offerToken: bayc.address,
      offerIdentifier: "3939",
      offerAmount: "1",
      considerationToken: "0x0000000000000000000000000000000000000000",
      considerationIdentifier: "0",
      // considerationAmount: price,
      considerationAmount: "77662500000000000000",
      offerer: "0xaf0f4479af9df756b9b2c69b463214b9a3346443",
      zone: "0x004C00500000aD104D7DBd00e3ae0A5C00560C00",
      zoneHash: "0x0000000000000000000000000000000000000000000000000000000000000000",
      salt: "69803129318312405",
      offererConduitKey: "0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000",
      fulfillerConduitKey: "0x0000000000000000000000000000000000000000000000000000000000000000",
      startTime: "1659635910",
      endTime: "1660089258",
      basicOrderType: 2,
      signature:
        "0x54e1632c656462f23e349fdf12fef25fb91008592544b4b3d9c2a694b55fbc6433e97d0d8258f8b3309513ee150f6cacd12cde0b4c793bc21e42b286959be4651c",
      totalOriginalAdditionalRecipients: 2,
      additionalRecipients: [
        {
          amount: "2043750000000000000",
          recipient: "0x8De9C5A032463C561423387a9648c5C7BCC5BC90",
        },
        {
          amount: "2043750000000000000",
          recipient: "0xA858DDc0445d8131daC4d1DE01f834ffcbA52Ef1",
        },
      ],
    };

    const seaportInterface = new ethers.utils.Interface([
      "function fulfillBasicOrder(tuple(address considerationToken, uint256 considerationIdentifier, uint256 considerationAmount, address offerer, address zone, address offerToken, uint256 offerIdentifier, uint256 offerAmount, uint8 basicOrderType, uint256 startTime, uint256 endTime, bytes32 zoneHash, uint256 salt, bytes32 offererConduitKey, bytes32 fulfillerConduitKey, uint256 totalOriginalAdditionalRecipients, tuple(uint256 amount, address recipient)[] additionalRecipients, bytes signature)) payable returns (bool)",
    ]);

    const calldata = seaportInterface.encodeFunctionData("fulfillBasicOrder", [basicOrderParameters]);

    const tx = await aggregator.buyWithETH([{ data: calldata, value: price }], { value: price });
    await tx.wait();

    expect(await bayc.balanceOf(buyer.address)).to.equal(1);
    expect(await bayc.ownerOf(3939)).to.equal(buyer.address);
  });
});
