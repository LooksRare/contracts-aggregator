// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Script} from "forge-std/Script.sol";
import {LooksRareAggregator} from "../contracts/LooksRareAggregator.sol";
import {LooksRareProxy} from "../contracts/proxies/LooksRareProxy.sol";
import {SeaportProxy} from "../contracts/proxies/SeaportProxy.sol";
import {X2Y2Proxy} from "../contracts/proxies/X2Y2Proxy.sol";
import {CryptoPunksProxy} from "../contracts/proxies/CryptoPunksProxy.sol";
import {SudoswapProxy} from "../contracts/proxies/SudoswapProxy.sol";

contract MainnetDeploymentParameters {
    address internal constant LOOKSRARE_V1 = 0x59728544B08AB483533076417FbBB2fD0B17CE3a;
}

contract GoerliDeploymentParameters {
    address internal constant LOOKSRARE_V1 = 0xD112466471b5438C1ca2D218694200e49d81D047;
}

contract Deployment is Script {
    LooksRareAggregator internal looksRareAggregator;
    LooksRareProxy internal looksRareProxy;
    SeaportProxy internal seaportProxy;
    X2Y2Proxy internal x2y2Proxy;
    CryptoPunksProxy internal cryptoPunksProxy;
    SudoswapProxy internal sudoswapProxy;

    error WrongChain();

    function _run(address looksrare, address seaport) internal {
        vm.startBroadcast();

        looksRareAggregator = new LooksRareAggregator();
        _deployLooksRareProxy(looksrare);
        _deploySeaportProxy(seaport);

        vm.stopBroadcast();
    }

    function _deployLooksRareProxy(address marketplace) private {
        looksRareProxy = new LooksRareProxy(marketplace);
        looksRareAggregator.addFunction(address(looksRareProxy), LooksRareProxy.execute.selector);
    }

    function _deploySeaportProxy(address marketplace) private {
        seaportProxy = new SeaportProxy(marketplace);
        looksRareAggregator.addFunction(address(seaportProxy), SeaportProxy.execute.selector);
    }

    function _deployX2Y2Proxy(address marketplace) private {
        x2y2Proxy = new X2Y2Proxy(marketplace);
        looksRareAggregator.addFunction(address(x2y2Proxy), X2Y2Proxy.execute.selector);
    }

    function _deployCryptoPunksProxy(address marketplace) private {
        cryptoPunksProxy = new CryptoPunksProxy(marketplace);
        looksRareAggregator.addFunction(address(cryptoPunksProxy), CryptoPunksProxy.execute.selector);
    }

    function _deploySudoswapProxy(address marketplace) private {
        require(false, "Wait until Sudoswap router V2 is available");
        sudoswapProxy = new SudoswapProxy(marketplace);
        looksRareAggregator.addFunction(address(sudoswapProxy), SudoswapProxy.execute.selector);
    }
}
