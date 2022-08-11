import { ethers } from "hardhat";
import { SEAPORT_ORDER_EXTRA_DATA_SCHEMA } from "../../constants";
import Consideration from "../interfaces/consideration";
import Order from "../interfaces/order";

export default function getSeaportOrderExtraData(order: Order): string {
  const abiCoder = ethers.utils.defaultAbiCoder;
  return abiCoder.encode(
    [SEAPORT_ORDER_EXTRA_DATA_SCHEMA],
    [
      {
        orderType: order.parameters.orderType,
        zone: order.parameters.zone,
        zoneHash: order.parameters.zoneHash,
        salt: order.parameters.salt,
        conduitKey: order.parameters.conduitKey,
        recipients: order.parameters.consideration.map((item: Consideration) => ({
          recipient: item.recipient,
          amount: item.endAmount,
        })),
      },
    ]
  );
}
