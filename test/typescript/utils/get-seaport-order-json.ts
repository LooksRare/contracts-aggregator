import SeaportOrder from "../interfaces/seaport/order";
import { BigNumber } from "ethers";
import combineConsiderationAmount from "./combine-consideration-amount";

export interface OrderJson {
  price: BigNumber;
  signer: string;
  collection: string;
  collectionType: number;
  tokenIds: string[];
  amounts: number[];
  currency: string;
  startTime: number;
  endTime: number;
  signature: string;
}

export default function getSeaportOrderJson(listing: SeaportOrder): OrderJson {
  const order = {
    price: combineConsiderationAmount(listing.parameters.consideration),
    signer: listing.parameters.offerer,
    collection: listing.parameters.offer[0].token,
    collectionType: Number(listing.parameters.offer[0].itemType) === 2 ? 0 : 1,
    tokenIds: [listing.parameters.offer[0].identifierOrCriteria],
    amounts: [1],
    currency: listing.parameters.consideration[0].token,
    startTime: listing.parameters.startTime,
    endTime: listing.parameters.endTime,
    signature: listing.signature,
  };

  return order;
}
