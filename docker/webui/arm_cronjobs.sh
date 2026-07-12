#!/bin/sh

echo "0 */6 * * * nginx -s reload" >> /etc/crontabs/root
