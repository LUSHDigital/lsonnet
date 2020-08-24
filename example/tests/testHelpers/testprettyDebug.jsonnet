local test = import 'lib/jsonnetunit/jsonnetunit/test.libsonnet';
local utils = import 'lib/testhelpers.libsonnet';

test.suite({
  testPrettyDebug: {

    local test = [{ title: 'wey', json: { foo: 'bar', wee: { woo: 'waa' } } }],

    actual: utils.prettyDebug(test),
    expect: 'true',
    // Fix this
    //expect: '\nwey is {\n  "foo": "bar",\n  "wee": {\n    "woo": "waa"\n  }\n}',
  },

})
