import behavesLikeSeaportERC721OnlyUSDCOrders from "./shared-tests/behaves-like-seaport-erc-721-only-usdc-orders";

describe("Aggregator", () => {
  behavesLikeSeaportERC721OnlyUSDCOrders(false);
});
