local config = import 'config/config.libsonnet';
local test = import 'lib/jsonnetunit/jsonnetunit/test.libsonnet';
local utils = import 'lib/testhelpers.libsonnet';

local debug = (
  if config.trace then
    utils.prettyDebug([{ title: 'config', json: config }])
);

local results = test.suite({
  testServiceImage: { actual: config.service.image, expect: 'foo' },
  testServiceTag: { actual: config.service.tag, expect: 'bar' },
  testLabels: { actual: config.labels, expect: { app: 'test-serviceName' } },
  testSelector: { actual: config.selector, expect: { app: 'test-serviceName' } },
});

{
  results: results,
  debug: debug,
}
