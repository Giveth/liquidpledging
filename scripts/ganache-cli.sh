#!/usr/bin/env bash

echo "Starting test server..."

# Exit script as soon as a command fails.
set -o errexit

if [ "$SOLIDITY_COVERAGE" = true ]; then
  testrpc_port=8555
else
  testrpc_port=8545
fi

testrpc_running() {
  nc -z localhost "$testrpc_port"
}

start_testrpc() {
  if [ "$SOLIDITY_COVERAGE" = true ]; then
    node_modules/.bin/testrpc-sc -a 20 -i 16 --gasLimit 0xfffffffffff --port "$testrpc_port"  > /dev/null &
  else
    node_modules/.bin/ganache-cli -a 20 -v -i 15 --gasLimit 6700000  > /dev/null &
  fi

  testrpc_pid=$!
}

if testrpc_running; then
  echo "Using existing testrpc instance at port $testrpc_port"
else
  echo "Starting our own testrpc instance at port $testrpc_port"
  start_testrpc
fi
