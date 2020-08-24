local vars = import 'config/config.libsonnet';
local test = import 'lib/jsonnetunit/jsonnetunit/test.libsonnet';
local utils = import 'lib/testhelpers.libsonnet';
local cronjob = import 'templates/cronjob.libsonnet';

local results = test.suite({
  // test overall output
  testTheShouldBeTwoJobsPresent: {
    actual: std.length(cronjob),
    expect: 2,
  },

  // concentrate on just one job
  local job1 = cronjob[0],
  local job2 = cronjob[1],

  testJobKind: {
    actual: job1.kind,
    expect: 'CronJob',
  },

  testapiVersion: {
    actual: job1.apiVersion,
    expect: 'batch/v1beta1',
  },

  testCronJobName: {
    actual: job1.metadata.name,
    expect: 'serviceName-job1-job',
  },

  testCronImage: {
    local cronContainer = job1.spec.jobTemplate.spec.template.spec.containers[0],
    actual: cronContainer.image,
    expect: 'testImage:testTag',
  },

  testCronCommand: {
    actual: job1.spec.jobTemplate.spec.template.spec.containers[0].command,
    expect: ['curl', 'https://google.com'],
  },

  testAdditionalEnvVars: {
    actual: utils.containsEnvVars(
      job1.spec.jobTemplate.spec.template.spec.containers[0].env,
      [{ name: 'keyOne', value: 'valueOne' }]
    ),
    expect: true,
  },

  testCronSchedule: {
    actual: job1.spec.schedule,
    expect: '1 2 3 4 5',
  },

  testRestartPolicy: {
    actual: job1.spec.jobTemplate.spec.template.spec.restartPolicy,
    expect: 'Never',
  },
});

local debug = (
  if vars.trace then
    utils.prettyDebug([{ title: 'cronjob', json: cronjob }])
);

{
  results: results,
  debug: debug,
}
