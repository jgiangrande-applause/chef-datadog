# Configure a service via its yaml file

default_action :add

property :name, String, name_attribute: true
property :cookbook, String, default: 'datadog'

# checks have 3 sections: init_config, instances, logs
# we mimic these here, no validation is performed until the template
# is evaluated.
property :init_config, [Hash, nil], required: false, default: {}
property :instances, Array, required: false, default: []
property :version, [Integer, nil], required: false, default: nil
property :use_integration_template, [TrueClass, FalseClass], required: false, default: false
property :logs, [Array, nil], required: false, default: []

action :add do
  Chef::Log.debug("Adding monitoring for #{new_resource.name}")

  template ::File.join(yaml_dir, "#{new_resource.name}.yaml") do
    # On Windows Agent v5, set the permissions on conf files to Administrators.
    if node['platform_family'] == 'windows'
      unless node['datadog']['agent6']
        owner 'Administrators'
        rights :full_control, 'Administrators'
        inherits false
      end
    else
      owner 'dd-agent'
      mode '600'
    end

    source 'integration.yaml.erb' if new_resource.use_integration_template

    variables(
      init_config: new_resource.init_config,
      instances:   new_resource.instances,
      version:     new_resource.version,
      logs:        new_resource.logs
    )
    cookbook new_resource.cookbook
    sensitive true
  end
end

action :remove do
  Chef::Log.debug("Removing #{new_resource.name} from #{yaml_dir}")

  file ::File.join(yaml_dir, "#{new_resource.name}.yaml") do
    action :delete
    sensitive true
  end
end

def yaml_dir
  if node['datadog']['agent6']
    ::File.join(node['datadog']['agent6_config_dir'], 'conf.d')
  else
    ::File.join(node['datadog']['config_dir'], 'conf.d')
  end
end
