import pytest
import sys
import os
import re
os.environ['SENTINEL_ENV'] = 'test'
os.environ['SENTINEL_CONFIG'] = os.path.normpath(os.path.join(os.path.dirname(__file__), '../test_sentinel.conf'))
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', 'lib'))
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))
import config

from collegicoind import ProtonDaemon
from collegicoin_config import ProtonConfig


def test_collegicoind():
    config_text = ProtonConfig.slurp_config_file(config.collegicoin_conf)
    network = 'mainnet'
    is_testnet = False
    genesis_hash = u'00000e1728b630fd83aecbc51546c7915fffb7d3c897b5fd8c4b14043070b7f0'
    for line in config_text.split("\n"):
        if line.startswith('testnet=1'):
            network = 'testnet'
            is_testnet = True
            genesis_hash = u'0000000f350d9039575f6446584f4ae4317bed76aae26ef1f2381ff73f7cd68d'

    creds = ProtonConfig.get_rpc_creds(config_text, network)
    collegicoind = ProtonDaemon(**creds)
    assert collegicoind.rpc_command is not None

    assert hasattr(collegicoind, 'rpc_connection')

    # Proton testnet block 0 hash == 0000000f350d9039575f6446584f4ae4317bed76aae26ef1f2381ff73f7cd68d
    # test commands without arguments
    info = collegicoind.rpc_command('getinfo')
    info_keys = [
        'blocks',
        'connections',
        'difficulty',
        'errors',
        'protocolversion',
        'proxy',
        'testnet',
        'timeoffset',
        'version',
    ]
    for key in info_keys:
        assert key in info
    assert info['testnet'] is is_testnet

    # test commands with args
    assert collegicoind.rpc_command('getblockhash', 0) == genesis_hash
