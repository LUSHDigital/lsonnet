local vars = import '../config/config.libsonnet';

{
  apiVersion: 'v1',
  kind: 'Service',
  metadata: {
    name: vars.service.name,
    namespace: vars.service.namespace,
    labels: vars.labels,
  },
  spec: {
    ports: [
      {
        port: 80,
        targetPort: 80,
        protocol: 'TCP',
        name: 'http',
      },
    ],
    type: 'NodePort',
    selector: vars.selector,
  },
}
