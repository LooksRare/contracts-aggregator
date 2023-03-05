// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Script} from "forge-std/Script.sol";
import {ERC20EnabledLooksRareAggregator} from "../../../contracts/ERC20EnabledLooksRareAggregator.sol";
import {LooksRareAggregator} from "../../../contracts/LooksRareAggregator.sol";
import {LooksRareProxy} from "../../../contracts/proxies/LooksRareProxy.sol";
import {LooksRareV2Proxy} from "../../../contracts/proxies/LooksRareV2Proxy.sol";
import {SeaportProxy} from "../../../contracts/proxies/SeaportProxy.sol";
import {IImmutableCreate2Factory} from "../../../contracts/interfaces/IImmutableCreate2Factory.sol";

contract Deployment is Script {
    LooksRareAggregator internal looksRareAggregator;
    LooksRareProxy internal looksRareProxy;
    SeaportProxy internal seaportProxy;

    IImmutableCreate2Factory private constant IMMUTABLE_CREATE2_FACTORY =
        IImmutableCreate2Factory(0x0000000000FFe8B47B3e2130213B802212439497);

    error WrongChain();

    function _run(address looksrare, address seaport) internal {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address looksRareAggregatorAddress = IMMUTABLE_CREATE2_FACTORY.safeCreate2({
            salt: vm.envBytes32("LOOKS_RARE_AGGREGATOR_SALT"),
            initializationCode: abi.encodePacked(
                type(LooksRareAggregator).creationCode,
                abi.encode(vm.envAddress("LOOKS_RARE_DEPLOYER"))
            )
        });

        address erc20EnabledLooksRareAggregatorAddress = IMMUTABLE_CREATE2_FACTORY.safeCreate2({
            salt: vm.envBytes32("ERC20_ENABLED_LOOKS_RARE_AGGREGATOR_SALT"),
            initializationCode: abi.encodePacked(
                type(ERC20EnabledLooksRareAggregator).creationCode,
                abi.encode(looksRareAggregatorAddress)
            )
        });

        looksRareAggregator = LooksRareAggregator(payable(looksRareAggregatorAddress));
        looksRareAggregator.setERC20EnabledLooksRareAggregator(erc20EnabledLooksRareAggregatorAddress);

        _deployLooksRareProxy(looksrare);
        _deploySeaportProxy(seaport);

        payable(address(looksRareAggregator)).transfer(1 wei);

        vm.stopBroadcast();
    }

    function _deployLooksRareProxy(address marketplace) private {
        // Just going to use the same salt for mainnet and goerli even though they will result
        // in 2 different contract addresses, as LooksRareExchange's contract address is different
        // for mainnet and goerli.
        address looksRareProxyAddress = IMMUTABLE_CREATE2_FACTORY.safeCreate2({
            salt: vm.envBytes32("LOOKS_RARE_PROXY_SALT"),
            initializationCode: abi.encodePacked(
                type(LooksRareProxy).creationCode,
                abi.encode(marketplace, address(looksRareAggregator))
            )
        });
        looksRareAggregator.addFunction(looksRareProxyAddress, LooksRareProxy.execute.selector);
    }

    function _deploySeaportProxy(address marketplace) private {
        address seaportProxyAddress = IMMUTABLE_CREATE2_FACTORY.safeCreate2({
            salt: vm.envBytes32("SEAPORT_PROXY_SALT"),
            initializationCode: abi.encodePacked(
                type(SeaportProxy).creationCode,
                abi.encode(marketplace, address(looksRareAggregator))
            )
        });
        looksRareAggregator.addFunction(seaportProxyAddress, SeaportProxy.execute.selector);
    }
}
