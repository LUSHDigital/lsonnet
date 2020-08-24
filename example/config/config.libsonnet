local default = import 'default.libsonnet';
local pipelineConfig = std.extVar('pipelineConfig');  // passed in via the cli
local appConfig = std.extVar('appConfig');  // passed in from an external config file

local externalConfig = std.mergePatch(appConfig, pipelineConfig);
local config = std.mergePatch(default, externalConfig);

local labels = {
  app: config.service.name,
};

local selector = {
  app: config.service.name,
};

config {
  labels: labels,
  selector: selector,
}
