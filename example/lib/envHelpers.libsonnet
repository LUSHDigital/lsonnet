local vars = import '../config/config.libsonnet';

{
  // This fn is used to take a key, return a simple `{name: key, value: valueOfKey}`
  // from the vars object
  // It is used for both envVars and secretEnvVars
  generateEnvVarsObject(key, keyObj):: (
    {
      name: key,
      value: std.toString(keyObj[key]),
    }
  ),

  generateSecretEnvVarsObject(key, keyObj):: (
    {
      name: keyObj[key].name,
      valueFrom: {
        secretKeyRef: {
          name: keyObj[key].secretName,
          key: keyObj[key].key,
        },
      },
    }
  ),

  // These maps contain env vars used in more than one place
  commonEnvVars: (
    [
      { name: 'SERVICE_NAME', value: vars.service.name },
    ]
  ),
}
