/* eslint-disable node/no-unpublished-import */
import { ethers } from "hardhat";
import axios from "axios";
import { RunInput } from "../test/typescript/interfaces/x2y2";
import { BAYC } from "../test/constants";
import * as fs from "fs";
import * as path from "path";

const orderItemParamType = `tuple(uint256 price, bytes data)`;
const orderParamType = `tuple(uint256 salt, address user, uint256 network, uint256 intent, uint256 delegateType, uint256 deadline, address currency, bytes dataMask, ${orderItemParamType}[] items, bytes32 r, bytes32 s, uint8 v, uint8 signVersion)`;
const feeParamType = `tuple(uint256 percentage, address to)`;
const settleDetailParamType = `tuple(uint8 op, uint256 orderIdx, uint256 itemIdx, uint256 price, bytes32 itemHash, address executionDelegate, bytes dataReplacement, uint256 bidIncentivePct, uint256 aucMinIncrementPct, uint256 aucIncDurationSecs, ${feeParamType}[] fees)`;
const settleSharedParamType = `tuple(uint256 salt, uint256 deadline, uint256 amountToEth, uint256 amountToWeth, address user, bool canFail)`;
const runInputParamType = `tuple(${orderParamType}[] orders, ${settleDetailParamType}[] details, ${settleSharedParamType} shared, bytes32 r, bytes32 s, uint8 v)`;
const decodeRunInput = (data: string): RunInput => {
  return ethers.utils.defaultAbiCoder.decode([runInputParamType], data)[0] as RunInput;
};

async function main() {
  const tokenId = "2674";
  const [buyer] = await ethers.getSigners();

  const x2y2Client = axios.create({
    baseURL: "https://api.x2y2.org",
    timeout: 5000,
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
  const input = inputData.find((d) => d.order_id === order.id);
  const runInput = input ? decodeRunInput(input.input) : undefined;

  if (runInput) {
    fs.writeFileSync(
      path.join(__dirname, `../test/typescript/fixtures/x2y2-bayc-${tokenId}-run-input.json`),
      JSON.stringify({
        orders: runInput.orders.map((order) => {
          return {
            salt: order.salt,
            user: order.user,
            network: order.network,
            intent: order.intent,
            delegateType: order.delegateType,
            deadline: order.deadline,
            currency: order.currency,
            dataMask: order.dataMask,
            items: order.items.map((item) => {
              return { price: item.price, data: item.data };
            }),
            r: order.r,
            s: order.s,
            v: order.v,
            signVersion: order.signVersion,
          };
        }),
        details: runInput.details.map((detail) => {
          return {
            op: detail.op,
            orderIdx: detail.orderIdx,
            itemIdx: detail.itemIdx,
            price: detail.price,
            itemHash: detail.itemHash,
            executionDelegate: detail.executionDelegate,
            dataReplacement: detail.dataReplacement,
            bidIncentivePct: detail.bidIncentivePct,
            aucMinIncrementPct: detail.aucMinIncrementPct,
            aucIncDurationSecs: detail.aucIncDurationSecs,
            fees: detail.fees.map((fee) => {
              return { percentage: fee.percentage, to: fee.to };
            }),
          };
        }),
        shared: {
          salt: runInput.shared.salt,
          deadline: runInput.shared.deadline,
          amountToEth: runInput.shared.amountToEth,
          amountToWeth: runInput.shared.amountToWeth,
          user: runInput.shared.user,
          canFail: runInput.shared.canFail,
        },
        v: runInput.v,
        r: runInput.r,
        s: runInput.s,
      })
    );
  }

  // eslint-disable-next-line no-process-exit
  process.exit(0);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
