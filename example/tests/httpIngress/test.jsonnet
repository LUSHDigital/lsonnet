local vars = import 'config/config.libsonnet';
local test = import 'lib/jsonnetunit/jsonnetunit/test.libsonnet';
local utils = import 'lib/testhelpers.libsonnet';
local ingress = import 'templates/ingress-http.libsonnet';

local results = test.suite({
  testApiVersion: {
    actual: ingress.apiVersion,
    expect: 'networking.k8s.io/v1beta1',
  },

  testName: {
    actual: ingress.metadata.name,
    expect: 'test-serviceName',
  },

  testNamespace: {
    actual: ingress.metadata.namespace,
    expect: 'test-namespace',
  },

  testAnnotations: {
    actual: ingress.metadata.annotations,
    expect: {
      'kubernetes.io/ingress.class': 'nginx',
    },
  },

  testShouldOnlyBeOneTLSCert: {
    actual: std.length(ingress.spec.tls),
    expect: 1,
  },

  testTlsSecretName: {
    actual: ingress.spec.tls[0],
    expect: { hosts: ['test-serviceName.woo.com'], secretName: 'wildcard-cert' },
  },

  testShouldBeOneBackendForTLS: {
    actual: std.length(ingress.spec.rules),
    expect: 1,
  },

  testTLSBackendHost: {
    local tlsBackend = ingress.spec.rules[0],

    actual: tlsBackend.host,
    expect: 'test-serviceName.woo.com',
  },

  testShouldBeOnePathForTLSBackend: {
    local tlsBackend = ingress.spec.rules[0],

    actual: std.length(tlsBackend.http.paths),
    expect: 1,
  },

  testTLSBackendPath: {
    local tlsBackend = ingress.spec.rules[0],

    actual: tlsBackend.http.paths[0],
    // TODO: can this be the named http port?
    expect: { path: '/', backend: { serviceName: 'test-serviceName', servicePort: 80 } },
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
