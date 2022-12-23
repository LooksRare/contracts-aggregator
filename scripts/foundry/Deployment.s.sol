// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Script} from "forge-std/Script.sol";
import {ERC20EnabledLooksRareAggregator} from "../../contracts/ERC20EnabledLooksRareAggregator.sol";
import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {LooksRareProxy} from "../../contracts/proxies/LooksRareProxy.sol";
import {SeaportProxy} from "../../contracts/proxies/SeaportProxy.sol";
import {X2Y2Proxy} from "../../contracts/proxies/X2Y2Proxy.sol";
import {CryptoPunksProxy} from "../../contracts/proxies/CryptoPunksProxy.sol";
import {SudoswapProxy} from "../../contracts/proxies/SudoswapProxy.sol";

contract Deployment is Script {
    ERC20EnabledLooksRareAggregator internal erc20EnabledLooksRareAggregator;
    LooksRareAggregator internal looksRareAggregator;
    LooksRareProxy internal looksRareProxy;
    SeaportProxy internal seaportProxy;
    X2Y2Proxy internal x2y2Proxy;
    CryptoPunksProxy internal cryptoPunksProxy;
    SudoswapProxy internal sudoswapProxy;

    address private constant OWNER = 0xFf6c307226343fCF96AF2f6B5B05f63F717e68cb;

    error WrongChain();

    function _run(address looksrare, address seaport) internal {
        vm.startBroadcast();

        looksRareAggregator = new LooksRareAggregator(OWNER);

        erc20EnabledLooksRareAggregator = new ERC20EnabledLooksRareAggregator(address(looksRareAggregator));
        looksRareAggregator.setERC20EnabledLooksRareAggregator(address(erc20EnabledLooksRareAggregator));

        _deployLooksRareProxy(looksrare);
        _deploySeaportProxy(seaport);

        vm.stopBroadcast();
    }

    function _deployLooksRareProxy(address marketplace) private {
        looksRareProxy = new LooksRareProxy(marketplace, address(looksRareAggregator));
        looksRareAggregator.addFunction(address(looksRareProxy), LooksRareProxy.execute.selector);
    }

    function _deploySeaportProxy(address marketplace) private {
        seaportProxy = new SeaportProxy(marketplace, address(looksRareAggregator));
        looksRareAggregator.addFunction(address(seaportProxy), SeaportProxy.execute.selector);
    }

    function _deployX2Y2Proxy(address marketplace) private {
        x2y2Proxy = new X2Y2Proxy(marketplace, address(looksRareAggregator));
        looksRareAggregator.addFunction(address(x2y2Proxy), X2Y2Proxy.execute.selector);
    }

    function _deployCryptoPunksProxy(address marketplace) private {
        cryptoPunksProxy = new CryptoPunksProxy(marketplace, address(looksRareAggregator));
        looksRareAggregator.addFunction(address(cryptoPunksProxy), CryptoPunksProxy.execute.selector);
    }

    function _deploySudoswapProxy(address marketplace) private {
        require(false, "Wait until Sudoswap router V2 is available");
        sudoswapProxy = new SudoswapProxy(marketplace, address(looksRareAggregator));
        looksRareAggregator.addFunction(address(sudoswapProxy), SudoswapProxy.execute.selector);
    }
}
