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

    function testDeploymentAddresses() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"));

        address deployer = vm.envAddress("LOOKS_RARE_DEPLOYER");

        vm.startPrank(deployer);

        address looksRareAggregatorAddress = CREATE2_FACTORY.safeCreate2({
            salt: vm.envBytes32("LOOKS_RARE_AGGREGATOR_SALT"),
            initializationCode: abi.encodePacked(type(LooksRareAggregator).creationCode, abi.encode(deployer))
        });

        assertEq(looksRareAggregatorAddress, 0x0000000000b83f088A8F61D8a792cBA2A672239a);
        assertEq(LooksRareAggregator(payable(looksRareAggregatorAddress)).owner(), deployer);

        address erc20EnabledLooksRareAggregatorAddress = CREATE2_FACTORY.safeCreate2({
            salt: vm.envBytes32("ERC20_ENABLED_LOOKS_RARE_AGGREGATOR_SALT"),
            initializationCode: abi.encodePacked(
                type(ERC20EnabledLooksRareAggregator).creationCode,
                abi.encode(looksRareAggregatorAddress)
            )
        });

        assertEq(erc20EnabledLooksRareAggregatorAddress, 0x00000000008dc76706d35a7A032105798266B89D);
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

        assertEq(looksRareProxyAddress, 0x000000000016bc517901ACeB561180C7aE5Bd4D7);
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

        assertEq(seaportProxyAddress, 0x0000000000B356f6B4DfDA6de3735d5099c2aF2b);
        SeaportProxy seaportProxy = SeaportProxy(payable(seaportProxyAddress));
        assertEq(address(seaportProxy.marketplace()), SEAPORT);
        assertEq(seaportProxy.aggregator(), looksRareAggregatorAddress);

        vm.stopPrank();
    }
}
