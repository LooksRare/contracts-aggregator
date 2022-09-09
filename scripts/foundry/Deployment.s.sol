// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {Script} from "forge-std/Script.sol";
import {LooksRareAggregator} from "../contracts/LooksRareAggregator.sol";
import {LooksRareProxy} from "../contracts/proxies/LooksRareProxy.sol";
import {SeaportProxy} from "../contracts/proxies/SeaportProxy.sol";
import {X2Y2Proxy} from "../contracts/proxies/X2Y2Proxy.sol";
import {CryptoPunksProxy} from "../contracts/proxies/CryptoPunksProxy.sol";
import {SudoswapProxy} from "../contracts/proxies/SudoswapProxy.sol";

contract Deployment is Script {
    LooksRareAggregator looksRareAggregator;
    LooksRareProxy looksRareProxy;
    SeaportProxy seaportProxy;
    X2Y2Proxy x2y2Proxy;
    CryptoPunksProxy cryptoPunksProxy;
    SudoswapProxy sudoswapProxy;

    function run() public {
        vm.startBroadcast();

        looksRareAggregator = new LooksRareAggregator();

        looksRareProxy = new LooksRareProxy(0x59728544B08AB483533076417FbBB2fD0B17CE3a);
        looksRareAggregator.addFunction(address(looksRareProxy), LooksRareProxy.execute.selector);

        seaportProxy = new SeaportProxy(0x00000000006c3852cbEf3e08E8dF289169EdE581);
        looksRareAggregator.addFunction(address(seaportProxy), SeaportProxy.execute.selector);

        x2y2Proxy = new X2Y2Proxy(0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3);
        looksRareAggregator.addFunction(address(x2y2Proxy), X2Y2Proxy.execute.selector);

        cryptoPunksProxy = new CryptoPunksProxy(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);
        looksRareAggregator.addFunction(address(cryptoPunksProxy), CryptoPunksProxy.execute.selector);

        // TODO: Wait until Sudoswap router V2 is available
        // sudoswapProxy = new SudoswapProxy(0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329);
        // looksRareAggregator.addFunction(address(sudoswapProxy), SudoswapProxy.execute.selector);

        vm.stopBroadcast();
    }
}
