FROM python:3.5-slim as dev
RUN pip install --upgrade pip
RUN pip install grpcio-tools

# Copy and build API
FROM dev as builder
COPY api api

RUN python3 -m grpc_tools.protoc \
    -Iapi/proto/v1 \
    --python_out=api/proto/v1 \
    --grpc_python_out=api/proto/v1 \
    api/proto/v1/service.proto

FROM python:3.5-slim as deploy
WORKDIR /usr/src/python-client

# Copy source code
COPY cmd/python-client/* ./
COPY --from=builder api/proto/v1/*.py ./

# Install runtime dependencies
RUN pip install -r requirements.txt

# Copy secrets
COPY secrets/root/public /secrets/root/public
COPY secrets/py-client /secrets/client
