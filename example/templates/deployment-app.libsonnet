local vars = import '../config/config.libsonnet';
local envVars = import '../lib/envHelpers.libsonnet';

local ports = (
  [{ name: 'http', containerPort: 80 }]
);

local healthChecks = (
  (if (std.objectHas(vars.healthChecks, 'livenessProbe')) then {
     livenessProbe: vars.healthChecks.livenessProbe,
   } else {}) +

  (if (std.objectHas(vars.healthChecks, 'readinessProbe')) then {
     readinessProbe: vars.healthChecks.readinessProbe,
   } else {})
);

local deploy = {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: {
    name: vars.service.name,
    namespace: vars.service.namespace,
    labels: vars.labels,
  },
  spec: {
    replicas: vars.replicas,
    progressDeadlineSeconds: vars.healthChecks.deadline,
    minReadySeconds: vars.healthChecks.minReady,
    selector: {
      matchLabels: vars.selector { name: vars.service.name },
    },
    template: {
      metadata: {
        // This is a reference to the above
        labels: $.spec.selector.matchLabels,
      },
      spec: {
        containers: [
          {
            name: vars.service.name,
            image: vars.service.image + ':' + vars.service.tag,
            imagePullPolicy: vars.service.pullPolicy,
            ports: ports,
            resources: vars.resources,
            env:
              envVars.commonEnvVars
              + (if std.objectHas(vars, 'envVars') then [
                   // for every key in vars.envVars, generate a {name: k, value: v} object and add to array
                   envVars.generateEnvVarsObject(key, vars.envVars)
                   for key in std.objectFields(vars.envVars)
                 ] else [])
              + (if std.objectHas(vars, 'secretEnvVars') then [
                   // for every key in vars.secretEnvVars, generate a {name: k, value: v} object and add to array
                   envVars.generateSecretEnvVarsObject(key, vars.secretEnvVars)
                   for key in std.objectFields(vars.secretEnvVars)
                 ] else []),
          } + healthChecks,
        ],
        restartPolicy: 'Always',
      },
    },
  },
};

deploy
