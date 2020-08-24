{
  service: {
    name: 'test-serviceName',
    namespace: 'test-namespace',
    hostname: 'test-serviceName.woo.com',
    image: 'hello-world',
    tag: 'latest',
    pullPolicy: 'IfNotPresent',
    ingress: false,
  },
  // Comment out sections we may not need
  //extraJobs: [
  //  {
  //    name: 'job1',
  //    command: 'curl https://google.com',
  //    enableDb: true,
  //    image: {
  //      repository: 'testImage',
  //      tag: 'testTag',
  //    },
  //    restartPolicy: 'Never',
  //    schedule: '1 2 3 4 5',
  //    envVars: {
  //      keyOne: 'valueOne',
  //    },
  //  },
  //],

  // Health checks set up readyness and liveness probes
  // Liveness probes will restart pods if they fail
  // Readyness probes will stop sending traffic to that pod
  // until it succeeds
  // Full spec here: https:// kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
  healthChecks: {
    deadline: 300,
    minReady: 30,
    livenessProbe: {
      httpGet: {
        path: '/-/healthy',
        port: 80,
      },
      initialDelaySeconds: 30,
      timeoutSeconds: 30,
    },
    readinessProbe: {
      httpGet: {
        path: '/-/ready',
        port: 80,
      },
      initialDelaySeconds: 30,
      timeoutSeconds: 30,
    },
  },
  replicas: 3,
  // The resources available to the app container
  resources: {
    limits: {
      memory: '5Gi',
      cpu: '500m',
    },
    requests: {
      memory: '10Mi',
      cpu: '5m',
    },
  },
}
