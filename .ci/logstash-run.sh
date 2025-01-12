#!/bin/bash
set -ex

export PATH=$BUILD_DIR/gradle/bin:$PATH

wait_for_es() {
  echo "Waiting for elasticsearch to respond..."
  es_url="http://elasticsearch:9200"
  if [[ "$SECURE_INTEGRATION" == "true" ]]; then
    es_url="https://elasticsearch:9200 -k"
  fi
  count=120
  while ! curl --silent $es_url && [[ $count -ne 0 ]]; do
    count=$(( $count - 1 ))
    [[ $count -eq 0 ]] && return 1
    sleep 1
  done
  echo "Elasticsearch is Up !"

  return 0
}

if [[ "$INTEGRATION" != "true" ]]; then
  jruby -rbundler/setup -S rspec -fd --tag ~integration --tag ~secure_integration spec/inputs
else
  if [[ "$SECURE_INTEGRATION" == "true" ]]; then
    extra_tag_args="--tag secure_integration"
  else
    extra_tag_args="--tag ~secure_integration --tag integration"
  fi
  wait_for_es
  jruby -rbundler/setup -S rspec -fd $extra_tag_args --tag es_version:$ELASTIC_STACK_VERSION spec/inputs/integration
fi
