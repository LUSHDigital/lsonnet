local vars = import 'config/config.libsonnet';
local test = import 'lib/jsonnetunit/jsonnetunit/test.libsonnet';
local utils = import 'lib/testhelpers.libsonnet';
local deploy = import 'templates/deployment-app.libsonnet';

local results = test.suite({

  testApiVersion: {
    actual: deploy.apiVersion,
    expect: 'apps/v1',
  },

  testKind: {
    actual: deploy.kind,
    expect: 'Deployment',
  },

  testReplicaCount: {
    actual: deploy.spec.replicas,
    expect: 432,
  },

  testDeploymentName: {
    actual: deploy.metadata.name,
    expect: 'theServiceName',
  },

  testImageNameAndTag: {
    actual: deploy.spec.template.spec.containers[0].image,
    expect: 'theRepo:theTag',
  },

  testImagePullPolicy: {
    actual: deploy.spec.template.spec.containers[0].imagePullPolicy,
    expect: 'IfNotPresent',
  },

  testAllPortsAreSet: {
    actual: deploy.spec.template.spec.containers[0].ports,
    expect: [
      { name: 'http', containerPort: 80 },
    ],
  },

  testDeadlineSeconds: {
    actual: deploy.spec.progressDeadlineSeconds,
    expect: 300,
  },

  testMinReady: {
    actual: deploy.spec.minReadySeconds,
    expect: 30,
  },

  testNoCloudSqlContainer: {
    actual: std.length(deploy.spec.template.spec.containers),
    expect: 1,
  },

  testNoCloudSqlEnvVar: {
    actual: utils.containsEnvVars(
      deploy.spec.template.spec.containers[0].env,
      [
        { name: 'DB_USERNAME', value: 'proxyUser' },
      ]
    ),
    expect: false,
  },

  testResourceLimits: {
    actual: deploy.spec.template.spec.containers[0].resources,
    expect: { limits: { memory: '5Gi', cpu: '500m' }, requests: { memory: '10Mi', cpu: '5m' } },
  },

  testDefaultEnvVars: {
    local envVars = deploy.spec.template.spec.containers[0].env,

    actual: utils.containsEnvVars(envVars, [{ name: 'SERVICE_NAME', value: 'theServiceName' }]),
    expect: true,
  },

  testAdditionalEnvVars: {
    local envVars = deploy.spec.template.spec.containers[0].env,

    actual: utils.containsEnvVars(envVars, [{ name: 'ADDITIONAL_ENV', value: 'ADDITIONAL_VALUE' }]),
    expect: true,
  },

  testSecretEnvVars: {
    local envVars = deploy.spec.template.spec.containers[0].env,

    actual: utils.containsSecretEnvVars(envVars, [{ name: 'JWT_PRIVATE_KEY', valueFrom: { secretKeyRef: { key: 'app.rsa', name: 'jwtsigning' } } }]),
    expect: true,
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
