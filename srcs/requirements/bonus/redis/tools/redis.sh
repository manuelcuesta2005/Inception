#!/bin/sh

redis-cli config set bind 0.0.0.0
redis-cli config set protected-mode no

echo "[-] Redis Cache has started successfully..."
exec redis-server --protected-mode no