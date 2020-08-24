local test = import 'lib/jsonnetunit/jsonnetunit/test.libsonnet';
local utils = import 'lib/testhelpers.libsonnet';

local mockEnvs = [{ name: 'secret_name_1', valueFrom: { secretKeyRef: { key: 'secret_key_1', name: 'secret_name_1' } } }, { name: 'secret_name_2', valueFrom: { secretKeyRef: { key: 'secret_key_2', name: 'secret_name_2' } } }];

test.suite({
  testContainsSingleSecretEnvVars: {
    actual: utils.containsSecretEnvVars(
      mockEnvs,
      [{ name: 'secret_name_1', valueFrom: { secretKeyRef: { key: 'secret_key_1', name: 'secret_name_1' } } }]
    ),
    expect: true,
  },

  testContainsAllSecretEnvVars: {
    actual: utils.containsSecretEnvVars(
      mockEnvs,
      [{ name: 'secret_name_1', valueFrom: { secretKeyRef: { key: 'secret_key_1', name: 'secret_name_1' } } }, { name: 'secret_name_2', valueFrom: { secretKeyRef: { key: 'secret_key_2', name: 'secret_name_2' } } }]
    ),
    expect: true,
  },

  testDoesntSecretEnvVars: {
    actual: utils.containsSecretEnvVars(
      mockEnvs,
      [{ name: 'secret_name_3', valueFrom: { secretKeyRef: { key: 'secret_key_3', name: 'secret_name_3' } } }]
    ),
    expect: false,
  },
})
