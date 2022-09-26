import { BigNumber, constants } from "ethers";
import { ConsiderationItem } from "@opensea/seaport-js/lib/types";

export default function combineConsiderationAmount(consideration: Array<ConsiderationItem>): BigNumber {
  return consideration.reduce(
    (sum: BigNumber, item: ConsiderationItem) => BigNumber.from(item.endAmount).add(sum),
    constants.Zero
  );
}
