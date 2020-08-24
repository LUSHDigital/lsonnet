// These objects are referenced varies on how we execute the render
// In golang, this is done from the current working directory of the call
// Singletons return only a single object
local singletons = [
  import 'templates/deployment-app.libsonnet',
  import 'templates/ingress-http.libsonnet',
  import 'templates/service-app.libsonnet',
];

// We add templates that generate multiple objects to the singletons here
local objects = singletons
                + import 'templates/cronjob.libsonnet';

// If resources are not needed (eg if no ingress), the template returns null.
// Having a null (eg `[{...},null, {...},...]`) in your array breaks kubectl,
// so the below line filters it out
local items = std.prune(objects);

{
  apiVersion: 'v1',
  kind: 'List',
  items: items,
}
