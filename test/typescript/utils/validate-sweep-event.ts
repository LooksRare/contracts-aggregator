import { expect } from "chai";
import { ContractReceipt, ethers } from "ethers";
import { SWEEP_TOPIC } from "../../constants";

export default function validateSweepEvent(receipt: ContractReceipt, buyer: string): void {
  const event = receipt.events?.find((event) => event.topics[0] === SWEEP_TOPIC);
  // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
  expect(ethers.utils.getAddress(ethers.utils.hexStripZeros(event!.topics[1]))).to.equal(buyer);
}
