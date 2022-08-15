/* eslint-disable node/no-unpublished-import */
import { ethers } from "hardhat";
import axios from "axios";
import { RunInput } from "../test/typescript/interfaces/x2y2";
import { BAYC, PARALLEL } from "../test/constants";
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

const writeToFile = (collection: string, tokenId: string, input: any): void => {
  const runInput = input ? decodeRunInput(input.input) : undefined;

  if (runInput) {
    fs.writeFileSync(
      path.join(__dirname, `../test/typescript/fixtures/x2y2-${collection}-${tokenId}-run-input.json`),
      stringifyOrder(runInput)
    );
  }
};

const stringifyOrder = (runInput: RunInput): string => {
  return JSON.stringify({
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
  });
};

async function main() {
  const tokenIdOne = "2674";
  const tokenIdTwo = "2491";
  const tokenIdThree = "10511";
  const tokenIdFour = "10327";
  const [buyer] = await ethers.getSigners();

  const x2y2Client = axios.create({
    baseURL: "https://api.x2y2.org",
    timeout: 5000,
    headers: { "X-API-Key": process.env.X2Y2_API_KEY as string },
  });

  const ordersOneResponse = await x2y2Client.get(`/v1/orders?contract=${BAYC}&token_id=${tokenIdOne}&limit=1`);
  const ordersOne = ordersOneResponse.data;
  const orderOne = ordersOne.data[0];

  const ordersTwoResponse = await x2y2Client.get(`/v1/orders?contract=${BAYC}&token_id=${tokenIdTwo}&limit=1`);
  const ordersTwo = ordersTwoResponse.data;
  const orderTwo = ordersTwo.data[0];

  const ordersThreeResponse = await x2y2Client.get(`/v1/orders?contract=${PARALLEL}&token_id=${tokenIdThree}&limit=2`);
  const ordersThree = ordersThreeResponse.data;
  const orderThree = ordersThree.data[0];

  const ordersFourResponse = await x2y2Client.get(`/v1/orders?contract=${PARALLEL}&token_id=${tokenIdFour}&limit=2`);
  const ordersFour = ordersFourResponse.data;
  const orderFour = ordersFour.data[0];

  const signResponse = await x2y2Client.post("/api/orders/sign", {
    caller: buyer.address,
    op: 1, // OP_COMPLETE_SELL_OFFER
    amountToEth: "0",
    amountToWeth: "0",
    items: [
      { orderId: orderOne.id, currency: orderOne.currency, price: orderOne.price, tokenId: tokenIdOne },
      { orderId: orderTwo.id, currency: orderTwo.currency, price: orderTwo.price, tokenId: tokenIdTwo },
    ],
  });

  const signResponseTwo = await x2y2Client.post("/api/orders/sign", {
    caller: buyer.address,
    op: 1, // OP_COMPLETE_SELL_OFFER
    amountToEth: "0",
    amountToWeth: "0",
    items: [
      { orderId: orderThree.id, currency: orderThree.currency, price: orderThree.price, tokenId: tokenIdThree },
      { orderId: orderFour.id, currency: orderFour.currency, price: orderFour.price, tokenId: tokenIdFour },
    ],
  });

  // eslint-disable-next-line camelcase
  const inputData = (signResponse.data.data ?? []) as { order_id: number; input: string }[];
  const inputOne = inputData.find((d) => d.order_id === orderOne.id);
  const inputTwo = inputData.find((d) => d.order_id === orderTwo.id);
  writeToFile("bayc", tokenIdOne, inputOne);
  writeToFile("bayc", tokenIdTwo, inputTwo);

  // eslint-disable-next-line camelcase
  const inputDataTwo = (signResponseTwo.data.data ?? []) as { order_id: number; input: string }[];
  const inputThree = inputDataTwo.find((d) => d.order_id === orderThree.id);
  const inputFour = inputDataTwo.find((d) => d.order_id === orderFour.id);
  writeToFile("parallel", tokenIdThree, inputThree);
  writeToFile("parallel", tokenIdFour, inputFour);

  // eslint-disable-next-line no-process-exit
  process.exit(0);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
