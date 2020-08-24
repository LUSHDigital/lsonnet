local test = import 'lib/jsonnetunit/jsonnetunit/test.libsonnet';
local utils = import 'lib/testhelpers.libsonnet';

local mockEnvs = [{ name: 'n1', value: 'v1' }, { name: 'n2', value: 'v2' }, { name: 'n3', value: 'v3' }];

test.suite({
  testContainsSingleEnvVar: {
    expect: utils.containsEnvVars(mockEnvs, [{ name: 'n1', value: 'v1' }]),
    actual: true,
  },

  testContainsTwoEnvVars: {
    actual: utils.containsEnvVars(mockEnvs, [{ name: 'n2', value: 'v2' }, { name: 'n3', value: 'v3' }]),
    expect: true,
  },

  testDoesntContainsTwoEnvVars: {
    actual: utils.containsEnvVars(mockEnvs, [{ name: 'n5', value: 'v5' }, { name: 'n6', value: 'v6' }]),
    expect: false,
  },
})
