import enum
import grpc
import logging
import os

import service_pb2 as pb2
import service_pb2_grpc as pb2_grpc

class grpcClient:
    def __init__(self, uri, isPlaintext, isMutualAuth, secretsPath):
        self.uri = uri
        self.isPlaintext = isPlaintext
        self.isMutualAuth = isMutualAuth
        self.secretsPath = secretsPath

    def __root_ca_cert(self):
        return open(os.path.join(self.secretsPath, 'root/public/ca.cert'), 'rb').read()

    def __client_cert(self):
        return open(os.path.join(self.secretsPath, 'client/public/service.pem'), 'rb').read()

    def __client_private_key(self):
        return open(os.path.join(self.secretsPath, 'client/private/service.key'), 'rb').read()

    def __get_channel(self):
        if self.isPlaintext:
            logging.warn('Using plaintext channel to {}'.format(self.uri))
            return grpc.insecure_channel(target=self.uri)
        else:
            return grpc.secure_channel(
                target=self.uri, 
                credentials=self.__get_credentials(self.isMutualAuth))

    def __get_credentials(self, isMutualAuth):
        if not isMutualAuth:
            # a root CA is used to validate the authenticity of the certificate we will receive from the server
            logging.warn('Using server-authenticated TLS to {}'.format(self.uri))
            return grpc.ssl_channel_credentials(
                root_certificates = self.__root_ca_cert())
        else:
            # a root CA is used to validate the authenticity of the certificate we will receive from the server
            # and a client certificate is sent to the server so they can authenticate us
            logging.info('Using mTLS to {}'.format(self.uri))
            return grpc.ssl_channel_credentials(
                root_certificates  = self.__root_ca_cert(),
                certificate_chain  = self.__client_cert(),
                private_key        = self.__client_private_key())

    @staticmethod
    def __get_stub(channel):
        return pb2_grpc.GreeterStub(channel)

    def sayhello(self, name):
        with self.__get_channel() as channel:
            request = pb2.HelloRequest(name=name)
            logging.debug("sending gRPC Hello request")
            response = grpcClient.__get_stub(channel).SayHello(request=request)
            logging.debug('received response from gRPC server')
            return response
