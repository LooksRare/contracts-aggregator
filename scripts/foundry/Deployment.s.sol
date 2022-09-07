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

        looksRareProxy = new LooksRareProxy();
        looksRareAggregator.addFunction(address(looksRareProxy), LooksRareProxy.execute.selector);

        seaportProxy = new SeaportProxy();
        looksRareAggregator.addFunction(address(seaportProxy), SeaportProxy.execute.selector);

        x2y2Proxy = new X2Y2Proxy();
        looksRareAggregator.addFunction(address(x2y2Proxy), X2Y2Proxy.execute.selector);

        cryptoPunksProxy = new CryptoPunksProxy();
        looksRareAggregator.addFunction(address(cryptoPunksProxy), CryptoPunksProxy.execute.selector);

        sudoswapProxy = new SudoswapProxy();
        looksRareAggregator.addFunction(address(sudoswapProxy), SudoswapProxy.execute.selector);

        vm.stopBroadcast();
    }
}
