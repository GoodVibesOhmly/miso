from brownie import DutchAuctionFactory
from .settings import *
from .contracts import *
# from .contract_addresses import *
import time


def main():
    deployer = accounts.add(private_key="e35a21d3cef4022088a90f54c02cac3143737a6d3d3af1856ff182f2e4c22f9f")
    da = DutchAuctionFactory.deploy({"from": deployer})
    return da