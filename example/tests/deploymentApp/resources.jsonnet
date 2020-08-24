local vars = import 'config/config.libsonnet';
local test = import 'lib/jsonnetunit/jsonnetunit/test.libsonnet';
local utils = import 'lib/testhelpers.libsonnet';
local deploy = import 'templates/deployment-app.libsonnet';

local results = test.suite({
  testResourceLimits: {
    actual: deploy.spec.template.spec.containers[0].resources,
    expect: { limits: { memory: '10Gi', cpu: '2000m' }, requests: { memory: '500Mi', cpu: '100m' } },
  },
});

local debug = (
  if vars.trace then
    utils.prettyDebug([{ title: 'deploy', json: deploy }])
);

{
  results: results,
  debug: debug,
}
