from brownie import DutchAuction, accounts


def main(account):
    da = deploy_dutch_auction(account)
    init_dutch_auction(account, da)


def deploy_dutch_auction(account):
    acct = accounts.load(account)
    da = DutchAuction.deploy({"from": acct}, publish_source=True)

    return da


def init_dutch_auction(account, da):
    acct = accounts.load(account)
    da.initAuction(
        '0x5DfeDb20C722a9D4529B2B0948a3CE526BB6Fe90',  # Committee Multisig
        '0x747d453192D8A0B2e2184738033d0A6296301476',  # aPHM
        75000e18,
        '1643401800',  # Monday, 28 January 2022 8:30:00 PM UTC
        '1643661000',  # Monday, 31 January 2022 8:30:00 PM UTC
        '0xdc301622e621166bd8e82f2ca0a26c13ad0be355',  # FRAX
        2000e18,
        50e18,
        acct.address,  # Committee Multisig
        '0x0000000000000000000000000000000000000000',
        '0xTBD',  # PhantomDutchAuctionVault
        {"from": acct}
    )