import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";
import { BAYC, FULFILLER_CONDUIT_KEY, SEAPORT, ZONE_HASH } from "../constants";

describe("Seaport fulfillBasicOrder", () => {
  let bayc: Contract;
  let buyer: SignerWithAddress;

  beforeEach(async () => {
    [buyer] = await ethers.getSigners();

    await ethers.provider.send("hardhat_setBalance", [
      buyer.address,
      ethers.utils.parseEther("200").toHexString().replace("0x0", "0x"),
    ]);

    bayc = await ethers.getContractAt("IERC721", BAYC);
  });

  it("Should be able to handle OpenSea trades (fulfillBasicOrder)", async function () {
    const tokenId = "2518";
    const basicOrderParameters = {
      offerToken: bayc.address,
      offerIdentifier: tokenId,
      offerAmount: "1",
      considerationToken: "0x0000000000000000000000000000000000000000",
      considerationIdentifier: "0",
      considerationAmount: "79800000000000000000",
      offerer: "0x7a277cf6e2f3704425195caae4148848c29ff815",
      zone: "0x004C00500000aD104D7DBd00e3ae0A5C00560C00",
      zoneHash: ZONE_HASH,
      salt: "70769720963177607",
      offererConduitKey: "0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000",
      fulfillerConduitKey: FULFILLER_CONDUIT_KEY,
      startTime: "1659797236",
      endTime: "1662475636",
      basicOrderType: 2,
      signature:
        "0x27deb8f1923b96693d8d5e1bf9304207e31b9cb49e588e8df5b3926b7547ba444afafe429fb2a17b4b97544d8383f3ad886fc15cab5a91382a56f9d65bb3dc231c",
      totalOriginalAdditionalRecipients: 2,
      additionalRecipients: [
        {
          amount: "2100000000000000000",
          recipient: "0x8De9C5A032463C561423387a9648c5C7BCC5BC90",
        },
        {
          amount: "2100000000000000000",
          recipient: "0xA858DDc0445d8131daC4d1DE01f834ffcbA52Ef1",
        },
      ],
    };

    const seaportInstance = await ethers.getContractAt("SeaportInterface", SEAPORT);

    const price = ethers.utils.parseEther("84");
    const tx = await seaportInstance.connect(buyer).fulfillBasicOrder(basicOrderParameters, { value: price });
    await tx.wait();

    expect(await bayc.balanceOf(buyer.address)).to.equal(1);
    expect(await bayc.ownerOf(tokenId)).to.equal(buyer.address);
  });
});
