import Offer from "./offer";
import Consideration from "./consideration";
import { BytesLike } from "ethers";

interface Parameters {
  offerer: string;
  zone: string;
  offer: Offer[];
  consideration: Consideration[];
  orderType: number;
  startTime: number;
  endTime: number;
  zoneHash: BytesLike;
  salt: string;
  conduitKey: BytesLike;
  totalOriginalConsiderationItems: number;
}

export default interface SeaportOrder {
  parameters: Parameters;
  numerator: number;
  denominator: number;
  signature: string;
  extraData: string;
}
