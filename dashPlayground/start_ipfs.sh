#!/bin/bash
LIBP2P_FORCE_PNET=1 ipfs daemon --enable-gc --migrate --enable-pubsub-experiment 2>&1 >> ~/.ipfs/ipfs.log&
echo $! > ~/.ipfs/ipfs.pid
