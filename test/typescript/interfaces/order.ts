import Offer from "./offer";
import Consideration from "./consideration";

interface Parameters {
  offerer: string;
  zone: string;
  offer: Offer[];
  consideration: Consideration[];
  orderType: number;
  startTime: number;
  endTime: number;
  zoneHash: string;
  salt: string;
  conduitKey: string;
  totalOriginalConsiderationItems: number;
}

export default interface Order {
  parameters: Parameters;
  numerator: number;
  denominator: number;
  signature: string;
  extraData: string;
}
