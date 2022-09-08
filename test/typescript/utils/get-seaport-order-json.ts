import SeaportOrder from "../interfaces/seaport/order";
import { BigNumber } from "ethers";

interface OrderJson {
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

// TODO: Just use combineConsiderationAmount for price?
export default function getSeaportOrderJson(listing: SeaportOrder, price: BigNumber): OrderJson {
  const order = {
    price,
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
