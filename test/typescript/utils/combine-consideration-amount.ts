import Consideration from "../interfaces/consideration";
import { BigNumber, constants } from "ethers";

export default function combineConsiderationAmount(consideration: Array<Consideration>): BigNumber {
  return consideration.reduce(
    (sum: BigNumber, item: Consideration) => BigNumber.from(item.endAmount).add(sum),
    constants.Zero
  );
}
