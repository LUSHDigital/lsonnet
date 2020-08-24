local vars = import 'config/config.libsonnet';
local test = import 'lib/jsonnetunit/jsonnetunit/test.libsonnet';
local utils = import 'lib/testhelpers.libsonnet';
local ingress = import 'templates/ingress-http.libsonnet';

local results = test.suite({
  testIngress: {
    actual: ingress,
    expect: null,
  },
});

local debug = (
  if vars.trace then
    utils.prettyDebug([{ title: 'ingress', json: ingress }])
);

{
  results: results,
  debug: debug,
}
