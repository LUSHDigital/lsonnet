local test = import 'lib/jsonnetunit/jsonnetunit/test.libsonnet';
local utils = import 'lib/testhelpers.libsonnet';

test.suite({
  testContainsTheOnlyField: {

    local haystack = { k1: 'v1', k2: 'v2' },
    local search = { k1: 'v1', k2: 'v2' },

    actual: utils.containsObjects(haystack, search),
    expect: true,
  },

  testCanFindSubObjects: {
    local haystack = { k1: 'v1', k2: { sk1: 'sv1' } },
    local search = { k1: 'v1', k2: { sk1: 'sv1' } },

    actual: utils.containsObjects(haystack, search),
    expect: true,
  },

  testCanFindSingleNeedleInALargerObject: {
    local haystack = { k1: 'v1', k2: 'v2', k3: 'v3' },

    local needle = { k2: 'v2' },

    actual: utils.containsObjects(haystack, needle),
    expect: true,
  },

  testCantFindSingleNeedleInALargerObject: {
    local haystack = { k1: 'v1', k2: 'v2', k3: 'v3' },

    local needle = { k4: 'v4' },

    actual: utils.containsObjects(haystack, needle),
    expect: false,
  },
})
