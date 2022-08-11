import Consideration from "../interfaces/consideration";
import { BigNumber } from "ethers";

export default function combineConsiderationAmount(consideration: Array<any>): BigNumber {
  return consideration.reduce((sum: number, item: Consideration) => BigNumber.from(item.endAmount).add(sum), 0);
}
