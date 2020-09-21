#!/usr/bin/env python3

import argparse
import logging
import grpc
import os

import grpcClient as gc

def configureLogging():
    logging.basicConfig(
        format='%(asctime)s %(levelname)-8s %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S')
    logging.getLogger().setLevel(os.getenv('LOG_LEVEL', 'DEBUG'))

def parseCommandLine():
    parser = argparse.ArgumentParser(description='Example greeter client application')

    parser.add_argument('--url',
        default='localhost:8080',
        help='service endpoint URL')

    parser.add_argument('--plaintext',
        action='store_true',
        help='use plaintext not TLS (insecure)')

    parser.add_argument('--mTLS',
        action='store_true',
        help='use mutual authentication (as opposed to server-authentication)')

    parser.add_argument('--secretsPath',
        default='/secrets',
        help='path to the directory where certificates are stored')

    return parser.parse_args()

if __name__ == '__main__':
    configureLogging()
    args = parseCommandLine()
    logging.info('url={}, plaintext={}, mTLS={}, secretsPath={}'.format(args.url, args.plaintext, args.mTLS, args.secretsPath))

    client = gc.grpcClient(
        uri=args.url,
        isPlaintext=args.plaintext,
        isMutualAuth=args.mTLS,
        secretsPath=args.secretsPath)

    try:
        response = client.sayhello('python client')
        logging.info("Greeter responded with: {}".format(response.message))
    except grpc.RpcError as e:
        logging.error(e)
