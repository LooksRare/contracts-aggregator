/* eslint-disable camelcase */
import { BigNumberish } from "ethers";

export type TokenStandard = "erc721" | "erc1155";

export interface TokenPair {
  token: string;
  tokenId: BigNumberish;
  amount: BigNumberish;
  tokenStandard: TokenStandard;
}

export interface Order {
  item_hash: string;
  maker: string;
  type: string;
  side: number;
  status: string;
  currency: string;
  end_at: string;
  created_at: string;
  token: {
    contract: string;
    token_id: number;
    erc_type: TokenStandard;
  };
  id: number;
  price: string;
  taker: string | null;
}

export interface X2Y2OrderItem {
  price: BigNumberish;
  data: string;
}

export interface X2Y2Order {
  salt: BigNumberish;
  user: string;
  network: BigNumberish;
  intent: BigNumberish;
  delegateType: BigNumberish;
  deadline: BigNumberish;
  currency: string;
  dataMask: string;
  items: X2Y2OrderItem[];
  // signature
  r: string;
  s: string;
  v: number;
  signVersion: number;
}

export interface Fee {
  percentage: BigNumberish;
  to: string;
}

export interface SettleDetail {
  op: number;
  orderIdx: BigNumberish;
  itemIdx: BigNumberish;
  price: BigNumberish;
  itemHash: string;
  executionDelegate: string;
  dataReplacement: string;
  bidIncentivePct: BigNumberish;
  aucMinIncrementPct: BigNumberish;
  aucIncDurationSecs: BigNumberish;
  fees: Fee[];
}

export interface SettleShared {
  salt: BigNumberish;
  deadline: BigNumberish;
  amountToEth: BigNumberish;
  amountToWeth: BigNumberish;
  user: string;
  canFail: boolean;
}

export interface RunInput {
  orders: X2Y2Order[];
  details: SettleDetail[];
  shared: SettleShared;
  // signature
  r: string;
  s: string;
  v: number;
}
