import { expect } from "chai";
import { ContractReceipt } from "ethers";
import { SWEEP_TOPIC } from "../../constants";

export default function validateSweepEvent(
  receipt: ContractReceipt,
  buyer: string,
  expectedTradeCount: number,
  expectedSuccessCount: number
): void {
  const event = receipt.events?.find((event) => event.topics[0] === SWEEP_TOPIC);
  // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
  const { sweeper, tradeCount, successCount } = event!.args!;
  expect(sweeper).to.equal(buyer);
  expect(tradeCount).to.equal(expectedTradeCount);
  expect(successCount).to.equal(expectedSuccessCount);
}
