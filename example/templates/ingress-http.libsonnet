local vars = import '../config/config.libsonnet';

local annotations = (
  { 'kubernetes.io/ingress.class': 'nginx' }
);

if (vars.service.ingress) then
  {
    kind: 'Ingress',
    apiVersion: 'networking.k8s.io/v1beta1',
    metadata: {
      name: vars.service.name,
      namespace: vars.service.namespace,
      annotations: annotations,
      labels: vars.labels,
    },
    spec: {
      tls: [
        { hosts: [vars.service.hostname], secretName: 'wildcard-cert' },
      ],
      rules: [
        {
          host: vars.service.hostname,
          http: {
            paths: [
              {
                path: '/',
                backend: {
                  serviceName: vars.service.name,
                  // TODO: can this be the named http port?
                  servicePort: 80,
                },
              },
            ],
          },
        },
      ],
    },
  }
