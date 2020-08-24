local vars = import 'config/config.libsonnet';
local test = import 'lib/jsonnetunit/jsonnetunit/test.libsonnet';
local utils = import 'lib/testhelpers.libsonnet';
local service = import 'templates/service-app.libsonnet';

local results = test.suite({
  testType: { actual: service.spec.type, expect: 'NodePort' },
  testNamespace: { actual: service.metadata.namespace, expect: 'test-namespace' },
});

local debug = (
  if vars.trace then
    utils.prettyDebug([{ title: 'service', json: service }])
);

{
  results: results,
  debug: debug,
}
