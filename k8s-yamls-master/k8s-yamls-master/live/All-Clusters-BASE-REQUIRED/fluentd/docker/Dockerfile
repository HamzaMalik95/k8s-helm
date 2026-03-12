FROM docker-local.artifactory.medimpact.com/dockerhub/debian:bullseye-slim

LABEL version="1.0.3"

USER root

ENV FLUENTD_OPT=""
ENV FLUENTD_CONF="fluent.conf"

RUN buildDeps="ruby-dev make gcc g++" \
    && apt-get update \
    && apt-get install ruby $buildDeps libjemalloc2 -y \
    && gem install -N fluentd -v "1.15.3" \
    && gem install -N bigdecimal \
    && gem install -N jsonpath -v "1.1.2" \
    && gem install -N kubeclient -v "4.11.0" \
    && gem install -N thread_safe -v "0.3.6" \
    && gem install -N fluent-plugin-systemd -v "1.0.5" \
    && gem install -N fluent-plugin-concat -v "2.5.0" \
    && gem install -N fluent-plugin-jq -v "0.5.1" \
    && gem install -N fluent-plugin-multiline-parser -v "0.1.1" \
    && gem install -N fluent-plugin-json-parser -v "0.0.3" \
    && gem install -N fluent-plugin-splunk-enterprise -v "0.10.2" \
    && gem install -N fluent-plugin-rewrite-tag-filter -v "2.4.0" \
    && gem install -N fluent-plugin-kubernetes_metadata_filter -v "3.1.3" \
    && apt-get purge -y --auto-remove $buildDeps

COPY entrypoint.sh /fluentd/entrypoint.sh

RUN chmod 700 /fluentd/entrypoint.sh

WORKDIR /fluentd

# This makes fluentd use less memory
ENV LD_PRELOAD="/usr/lib/x86_64-linux-gnu/libjemalloc.so.2"

CMD ["/fluentd/entrypoint.sh"]