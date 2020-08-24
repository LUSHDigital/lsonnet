local vars = import '../config/config.libsonnet';
local envVars = import '../lib/envHelpers.libsonnet';

if (std.objectHas(vars, 'extraJobs')) then
  [
    {
      apiVersion: 'batch/v1beta1',
      kind: 'CronJob',
      metadata: {
        name: vars.service.name + '-' + cronjob.name + '-job',
        namespace: vars.service.namespace,
        labels: vars.labels,
      },
      spec: {
        schedule: cronjob.schedule,
        jobTemplate: {
          spec: {
            template: {
              metadata: { name: vars.service.name },
              spec: {
                containers: [
                  {
                    name: vars.service.name + cronjob.name,
                    image: cronjob.image.repository + ':' + cronjob.image.tag,
                    command: cronjob.command,
                    env: [] +
                         (if (std.objectHas(cronjob, 'envVars')) then [
                            envVars.generateEnvVarsObject(key, cronjob.envVars)
                            for key in std.objectFields(cronjob.envVars)
                          ] else []),
                  },
                ],
                restartPolicy: cronjob.restartPolicy,
              },
            },
          },
        },
      },
    }
    for cronjob in vars.extraJobs
  ] else []
