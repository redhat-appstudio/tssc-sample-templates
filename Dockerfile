# This Dockerfile is used to create a build in Konflux CI
# The build is required to run CI checks for pull request and push events in this repository.

FROM registry.access.redhat.com/ubi9/ubi:9.5-1745854298

LABEL KONFLUX_CI="true"

# renovate: datasource=repology depName=homebrew/openshift-cli
ARG OC_VERSION=4.17.9

# renovate: datasource=github-releases depName=mikefarah/yq
ARG YQ_VERSION=4.45.4

# renovate: datasource=github-releases depName=oras-project/oras
ARG ORAS_VERSION=1.2.3

# renovate: datasource=github-releases depName=sigstore/cosign
ARG COSIGN_VERSION=v2.5.0

RUN curl --proto "=https" --tlsv1.2 -sSf -LO "https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/oras_${ORAS_VERSION}_linux_amd64.tar.gz" && \
    mkdir -p oras-install/ && \
    tar -zxf oras_${ORAS_VERSION}_*.tar.gz -C oras-install/ && \
    mv oras-install/oras /usr/local/bin/ && \
    rm -rf oras_${ORAS_VERSION}_*.tar.gz oras-install/ && \
    oras version

RUN curl --proto "=https" --tlsv1.2 -sSf -L "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64" -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq && \
    yq --version

RUN curl --proto "=https" --tlsv1.2 -sSf -L "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OC_VERSION}/openshift-client-linux.tar.gz" -o /tmp/openshift-client-linux.tar.gz && \
    tar --no-same-owner -xzf /tmp/openshift-client-linux.tar.gz && \
    mv oc kubectl /usr/local/bin && \
    oc version --client && \
    kubectl version --client

ADD https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-amd64 /usr/local/bin/cosign
RUN chmod +x /usr/local/bin/cosign && \
    cosign version

USER 1001

RUN echo "# kubectl" && kubectl version --client && \
    echo "# oc" && oc version
