local vars = import 'config/config.libsonnet';
local test = import 'lib/jsonnetunit/jsonnetunit/test.libsonnet';
local utils = import 'lib/testhelpers.libsonnet';
local deploy = import 'templates/deployment-app.libsonnet';

local results = test.suite({
  testlivenessProbe: {
    actual: deploy.spec.template.spec.containers[0].livenessProbe,
    expect: { httpGet: { path: '/-/healthz', port: 8080 }, initialDelaySeconds: 30, timeoutSeconds: 40 },
  },

  testreadinessProbe: {
    actual: deploy.spec.template.spec.containers[0].readinessProbe,
    expect: { httpGet: { path: '/-/readyz', port: 9090 }, initialDelaySeconds: 50, timeoutSeconds: 60 },
  },

  testDeadlineSeconds: {
    actual: deploy.spec.progressDeadlineSeconds,
    expect: 350,
  },

  testMinReady: {
    actual: deploy.spec.minReadySeconds,
    expect: 60,
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
