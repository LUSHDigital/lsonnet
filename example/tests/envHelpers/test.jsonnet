local vars = import 'config/config.libsonnet';
local envVars = import 'lib/envHelpers.libsonnet';
local test = import 'lib/jsonnetunit/jsonnetunit/test.libsonnet';

test.suite({
  testEnvVarGeneration: {
    expect: envVars.generateEnvVarsObject('stuff', vars.envVars),
    actual: { name: 'stuff', value: 'blah' },
  },

  testSecretEnvVarGeneration: {
    expect: envVars.generateSecretEnvVarsObject('secretKey', vars.secretEnvVars),
    actual: { name: 'MY_SECRET_ENV_VAR', valueFrom: { secretKeyRef: { key: 'secretValue', name: 'kubeSecret' } } },
  },

  testCommonEnvVars: {
    local result = [
      { name: 'SERVICE_NAME', value: 'blah' },
    ],
    expect: envVars.commonEnvVars,
    actual: result,
  },
})
