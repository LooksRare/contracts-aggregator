import { BigNumber } from "ethers";

export default interface Offer {
  itemType: number;
  token: string;
  identifierOrCriteria: string;
  startAmount: BigNumber;
  endAmount: BigNumber;
}
