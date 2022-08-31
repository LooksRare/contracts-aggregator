import { BigNumber } from "ethers";

export default interface Consideration {
  itemType: number;
  token: string;
  identifierOrCriteria: string;
  startAmount: BigNumber;
  endAmount: BigNumber;
  recipient: string;
}
