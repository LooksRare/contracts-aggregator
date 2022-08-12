import { ethers } from "hardhat";
import { BAYC } from "../constants";
import axios from "axios";
import { RunInput } from "./interfaces/x2y2";

describe("LooksRareAggregator", () => {
  const orderItemParamType = `tuple(uint256 price, bytes data)`;
  const orderParamType = `tuple(uint256 salt, address user, uint256 network, uint256 intent, uint256 delegateType, uint256 deadline, address currency, bytes dataMask, ${orderItemParamType}[] items, bytes32 r, bytes32 s, uint8 v, uint8 signVersion)`;
  const feeParamType = `tuple(uint256 percentage, address to)`;
  const settleDetailParamType = `tuple(uint8 op, uint256 orderIdx, uint256 itemIdx, uint256 price, bytes32 itemHash, address executionDelegate, bytes dataReplacement, uint256 bidIncentivePct, uint256 aucMinIncrementPct, uint256 aucIncDurationSecs, ${feeParamType}[] fees)`;
  const settleSharedParamType = `tuple(uint256 salt, uint256 deadline, uint256 amountToEth, uint256 amountToWeth, address user, bool canFail)`;
  const runInputParamType = `tuple(${orderParamType}[] orders, ${settleDetailParamType}[] details, ${settleSharedParamType} shared, bytes32 r, bytes32 s, uint8 v)`;
  const decodeRunInput = (data: string): RunInput => {
    return ethers.utils.defaultAbiCoder.decode([runInputParamType], data)[0] as RunInput;
  };

  it("Should be able to handle X2Y2 trades", async function () {
    const [buyer] = await ethers.getSigners();

    const tokenId = "2491";

    const x2y2Client = axios.create({
      baseURL: "https://api.x2y2.org",
      timeout: 1000,
      headers: { "X-API-Key": process.env.X2Y2_API_KEY as string },
    });

    const ordersResponse = await x2y2Client.get(`/v1/orders?contract=${BAYC}&token_id=${tokenId}&limit=1`);
    const orders = ordersResponse.data;
    const order = orders.data[0];

    const signResponse = await x2y2Client.post("/api/orders/sign", {
      caller: buyer.address,
      op: 1, // OP_COMPLETE_SELL_OFFER
      amountToEth: "0",
      amountToWeth: "0",
      items: [{ orderId: order.id, currency: order.currency, price: order.price, tokenId }],
    });
    // eslint-disable-next-line camelcase
    const inputData = (signResponse.data.data ?? []) as { order_id: number; input: string }[];
    console.log(inputData);
    const input = inputData.find((d) => d.order_id === order.id);
    const runInput = input ? decodeRunInput(input.input) : undefined;
    console.log(runInput);
  });
});
