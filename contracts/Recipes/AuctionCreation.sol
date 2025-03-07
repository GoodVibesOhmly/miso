// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "../interfaces/IERC20.sol";
import "../Utils/SafeTransfer.sol";

interface IMisoTokenFactory {
    function createToken(
        uint256 _templateId,
        address payable _integratorFeeAccount,
        bytes calldata _data
    ) external payable returns (address token);
}

interface IPointList {
    function deployPointList(
        address _listOwner,
        address[] calldata _accounts,
        uint256[] calldata _amounts
    ) external payable returns (address pointList);
}

interface IMisoLauncher {
    function createLauncher(
        uint256 _templateId,
        address _token,
        uint256 _tokenSupply,
        address payable _integratorFeeAccount,
        bytes calldata _data
    ) external payable returns (address newLauncher);
}

interface IMisoMarket {
    function createMarket(
        uint256 _templateId,
        address _token,
        uint256 _tokenSupply,
        address payable _integratorFeeAccount,
        bytes calldata _data
    ) external payable returns (address newMarket);

    function setAuctionWallet(address payable _wallet) external;

    function addAdminRole(address _address) external;
}

// Auction Creation Recipe
// 1. Create Token
// 2. Create Whitelist (Optional)
// 3. Create Auction with token address and whitelist address
// 4. Create Liquidity Launcher with auction and token address 
// 5. Set destination wallet of auction to liquidity launcher
contract AuctionCreation is SafeTransfer {
    IMisoTokenFactory public misoTokenFactory;
    IPointList public pointListFactory;
    IMisoLauncher public misoLauncher;
    IMisoMarket public misoMarket;
    address public factory;

    constructor(
        IMisoTokenFactory _misoTokenFactory,
        IPointList _pointListFactory,
        IMisoLauncher _misoLauncher,
        IMisoMarket _misoMarket,
        address _factory
    ) public {
        misoTokenFactory = _misoTokenFactory;
        pointListFactory = _pointListFactory;
        misoLauncher = _misoLauncher;
        misoMarket = _misoMarket;
        factory = _factory;
    }

    function prepareMiso(
        bytes memory tokenFactoryData,
        address[] memory _accounts,
        uint256[] memory _amounts,
        bytes memory marketData,
        bytes memory launcherData
    ) external payable {
        require(_accounts.length == _amounts.length, "!len");

        address token;
        uint256 totalSupply;
        {
            (
                uint256 _misoTokenFactoryTemplateId,
                string memory _name,
                string memory _symbol,
                uint256 _initialSupply
            ) = abi.decode(
                    tokenFactoryData,
                    (uint256, string, string, uint256)
                );

            token = misoTokenFactory.createToken(
                _misoTokenFactoryTemplateId,
                address(0),
                abi.encode(_name, _symbol, msg.sender, _initialSupply)
            );
            totalSupply = _initialSupply;
            IERC20(token).approve(address(misoMarket), _initialSupply);
            IERC20(token).approve(address(misoLauncher), _initialSupply);
        }

        address pointList;
        if (_accounts.length != 0) {
            pointList = pointListFactory.deployPointList(
                msg.sender,
                _accounts,
                _amounts
            );
        }

        address newMarket;

        uint256 tokenForSale;

        {
            (uint256 _marketTemplateId, bytes memory mData) = abi.decode(
                marketData,
                (uint256, bytes)
            );
            tokenForSale = abi.decode(mData, (uint256));
            newMarket = misoMarket.createMarket(
                _marketTemplateId,
                token,
                tokenForSale,
                address(0),
                abi.encodePacked(
                    abi.encode(address(misoMarket), token),
                    mData,
                    abi.encode(address(this), pointList, msg.sender)
                )
            );
        }



        address newLauncher;
        {
            (
                uint256 _launcherTemplateId,
                uint256 _liquidityPercent,
                uint256 _locktime
            ) = abi.decode(launcherData, (uint256, uint256, uint256));

            newLauncher = misoLauncher.createLauncher(
                _launcherTemplateId,
                token,
                tokenForSale,
                address(0),
                abi.encode(
                    newMarket,
                    factory,
                    msg.sender,
                    msg.sender,
                    _liquidityPercent,
                    _locktime
                )
            );
        }

        // Miso market has to give admin role to the user, since it's set to this contract initially
        // to allow the auction wallet to be set to launcher once it's been deployed
        IMisoMarket(newMarket).addAdminRole(msg.sender);

        // Have to set auction wallet to the new launcher address AFTER the market is created
        // new launcher address is casted to payable to satisfy interface.                                                                                                           
        IMisoMarket(newMarket).setAuctionWallet(payable(newLauncher));

        uint256 tokenBalanceRemaining = IERC20(token).balanceOf(address(this));
        if (tokenBalanceRemaining > 0) {
            // Approve this contract to send remaining tokens back to the user
            IERC20(token).approve(address(this), tokenBalanceRemaining);

            _safeTransferFrom(
                token,
                address(this),
                msg.sender,
                tokenBalanceRemaining
            );
        }
    }
}
