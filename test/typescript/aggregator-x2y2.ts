import * as fs from "fs";
import * as path from "path";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import deployX2Y2Fixture from "./fixtures/deploy-x2y2-fixture";

describe("LooksRareAggregator", () => {
  it("Should be able to handle X2Y2 trades", async function () {
    const { aggregator, proxy, buyer, bayc } = await loadFixture(deployX2Y2Fixture);

    const tokenId = "2674";

    const orderFile = fs.readFileSync(path.join(__dirname, `/fixtures/x2y2-bayc-${tokenId}-run-input.json`), {
      encoding: "utf8",
      flag: "r",
    });
    const orderJson = JSON.parse(orderFile);
  });
});
