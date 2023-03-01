// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {ERC20EnabledLooksRareAggregator} from "../../contracts/ERC20EnabledLooksRareAggregator.sol";
import {IImmutableCreate2Factory} from "../../contracts/interfaces/IImmutableCreate2Factory.sol";
import {LooksRareProxy} from "../../contracts/proxies/LooksRareProxy.sol";
import {SeaportProxy} from "../../contracts/proxies/SeaportProxy.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TestParameters} from "./TestParameters.sol";
import {SeaportProxyTestHelpers} from "./SeaportProxyTestHelpers.sol";

contract DeploymentTest is TestParameters, TestHelpers, SeaportProxyTestHelpers {
    IImmutableCreate2Factory private constant CREATE2_FACTORY =
        IImmutableCreate2Factory(0x0000000000FFe8B47B3e2130213B802212439497);
    address private constant OWNER = 0x3ab105F0e4A22ec4A96a9b0Ca90c5C534d21f3a7;

    function testDeploymentAddresses() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"));

        vm.startPrank(vm.envAddress("LOOKS_RARE_DEPLOYER"));

        address looksRareAggregatorAddress = CREATE2_FACTORY.safeCreate2({
            salt: vm.envBytes32("LOOKS_RARE_AGGREGATOR_SALT"),
            initializationCode: abi.encodePacked(type(LooksRareAggregator).creationCode, abi.encode(OWNER))
        });

        assertEq(looksRareAggregatorAddress, 0x00000000005162DeeE2164C04bf38D07e8CCb58C);
        assertEq(LooksRareAggregator(payable(looksRareAggregatorAddress)).owner(), OWNER);

        address erc20EnabledLooksRareAggregatorAddress = CREATE2_FACTORY.safeCreate2({
            salt: vm.envBytes32("ERC20_ENABLED_LOOKS_RARE_AGGREGATOR_SALT"),
            initializationCode: abi.encodePacked(
                type(ERC20EnabledLooksRareAggregator).creationCode,
                abi.encode(looksRareAggregatorAddress)
            )
        });

        assertEq(erc20EnabledLooksRareAggregatorAddress, 0x0000000000a1fB13De019b2C97dF69D962Ee44f7);
        assertEq(
            address(ERC20EnabledLooksRareAggregator(payable(erc20EnabledLooksRareAggregatorAddress)).aggregator()),
            looksRareAggregatorAddress
        );

        address looksRareProxyAddress = CREATE2_FACTORY.safeCreate2({
            salt: vm.envBytes32("LOOKS_RARE_PROXY_SALT"),
            initializationCode: abi.encodePacked(
                type(LooksRareProxy).creationCode,
                abi.encode(LOOKSRARE_V1, looksRareAggregatorAddress)
            )
        });

        assertEq(looksRareProxyAddress, 0x000000000049b6299DaD91D63B996c7b91e56457);
        LooksRareProxy looksRareProxy = LooksRareProxy(payable(looksRareProxyAddress));
        assertEq(address(looksRareProxy.marketplace()), LOOKSRARE_V1);
        assertEq(looksRareProxy.aggregator(), looksRareAggregatorAddress);

        address seaportProxyAddress = CREATE2_FACTORY.safeCreate2({
            salt: vm.envBytes32("SEAPORT_PROXY_SALT"),
            initializationCode: abi.encodePacked(
                type(SeaportProxy).creationCode,
                abi.encode(SEAPORT, looksRareAggregatorAddress)
            )
        });

        assertEq(seaportProxyAddress, 0x00000000001181E39bE168843EA652a8959AF21B);
        SeaportProxy seaportProxy = SeaportProxy(payable(seaportProxyAddress));
        assertEq(address(seaportProxy.marketplace()), SEAPORT);
        assertEq(seaportProxy.aggregator(), looksRareAggregatorAddress);

        vm.stopPrank();
    }
}
