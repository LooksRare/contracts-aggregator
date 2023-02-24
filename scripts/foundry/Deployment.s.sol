// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Script} from "forge-std/Script.sol";
import {ERC20EnabledLooksRareAggregator} from "../../contracts/ERC20EnabledLooksRareAggregator.sol";
import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {LooksRareProxy} from "../../contracts/proxies/LooksRareProxy.sol";
import {SeaportProxy} from "../../contracts/proxies/SeaportProxy.sol";
import {IImmutableCreate2Factory} from "../../contracts/interfaces/IImmutableCreate2Factory.sol";

contract Deployment is Script {
    LooksRareAggregator internal looksRareAggregator;
    LooksRareProxy internal looksRareProxy;
    SeaportProxy internal seaportProxy;

    IImmutableCreate2Factory private constant CREATE2_FACTORY =
        IImmutableCreate2Factory(0x0000000000FFe8B47B3e2130213B802212439497);

    error WrongChain();

    function _run(
        address looksrare,
        address looksrareV2,
        address seaport
    ) internal {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address looksRareAggregatorAddress = CREATE2_FACTORY.safeCreate2({
            salt: vm.envBytes32("LOOKS_RARE_AGGREGATOR_SALT"),
            initializationCode: abi.encodePacked(
                type(LooksRareAggregator).creationCode,
                abi.encode(vm.envAddress("LOOKS_RARE_DEPLOYER"))
            )
        });

        address erc20EnabledLooksRareAggregatorAddress = CREATE2_FACTORY.safeCreate2({
            salt: vm.envBytes32("ERC20_ENABLED_LOOKS_RARE_AGGREGATOR_SALT"),
            initializationCode: abi.encodePacked(
                type(ERC20EnabledLooksRareAggregator).creationCode,
                abi.encode(looksRareAggregatorAddress)
            )
        });

        looksRareAggregator = LooksRareAggregator(looksRareAggregatorAddress);
        looksRareAggregator.setERC20EnabledLooksRareAggregator(erc20EnabledLooksRareAggregatorAddress);

        _deployLooksRareProxy(looksrare);
        _deployLooksRareV2Proxy(looksrareV2);
        _deploySeaportProxy(seaport);

        payable(address(looksRareAggregator)).transfer(1 wei);

        vm.stopBroadcast();
    }

    function _deployLooksRareProxy(address marketplace) private {
        // Just going to use the same salt for mainnet and goerli even though they will result
        // in 2 different contract addresses, as LooksRareExchange's contract address is different
        // for mainnet and goerli.
        address looksRareProxyAddress = CREATE2_FACTORY.safeCreate2({
            salt: vm.envBytes32("LOOKS_RARE_PROXY_SALT"),
            initializationCode: abi.encodePacked(
                type(LooksRareProxy).creationCode,
                abi.encode(marketplace, address(looksRareAggregator))
            )
        });
        looksRareAggregator.addFunction(looksRareProxyAddress, LooksRareProxy.execute.selector);
    }

    function _deployLooksRareV2Proxy(address marketplace) private {
        // Just going to use the same salt for mainnet and goerli even though they will result
        // in 2 different contract addresses, as LooksRareProtocol's contract address is different
        // for mainnet and goerli.
        address looksRareV2ProxyAddress = CREATE2_FACTORY.safeCreate2({
            salt: vm.envBytes32("LOOKS_RARE_V2_PROXY_SALT"),
            initializationCode: abi.encodePacked(
                type(LooksRareV2Proxy).creationCode,
                abi.encode(marketplace, address(looksRareAggregator))
            )
        });
        looksRareAggregator.addFunction(looksRareV2ProxyAddress, LooksRareV2Proxy.execute.selector);
    }

    function _deploySeaportProxy(address marketplace) private {
        address seaportProxyAddress = CREATE2_FACTORY.safeCreate2({
            salt: vm.envBytes32("SEAPORT_PROXY_SALT"),
            initializationCode: abi.encodePacked(
                type(SeaportProxy).creationCode,
                abi.encode(marketplace, address(looksRareAggregator))
            )
        });
        looksRareAggregator.addFunction(seaportProxyAddress, SeaportProxy.execute.selector);
    }
}
