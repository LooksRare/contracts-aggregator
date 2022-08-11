import Order from "../interfaces/order";
import { BigNumber } from "ethers";

interface OrderJson {
  price: BigNumber;
  recipient: string;
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

export default function getSeaportOrderJson(listing: Order, price: BigNumber, recipient: string): OrderJson {
  const order = {
    price,
    recipient,
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
