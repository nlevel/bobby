config = node['bobby']
cconfig = config['consul']

DEFAULT_CONSUL_CONFIG = {
  'path' => '/etc/consul/consul.json',
  'data_dir' => '/var/lib/consul',

  'client_addr' => '127.0.0.1',

  'ports' => {
    'dns'      => 8600,
    'http'     => 8500,
    'serf_lan' => 8301,
    'serf_wan' => 8302,
    'server'   => 8300,
  }
}

consul_enabled = false
consul_config = nil
ph = Bobby::ParamsHelper.new(self)

if cconfig['server']
  consul_config = DEFAULT_CONSUL_CONFIG.merge({ 'server' => true,
                                                'bootstrap_expect' => 1 })
else
  consul_config = DEFAULT_CONSUL_CONFIG.merge({ 'server' => false })
end

unless cconfig['client_addr'].nil?
  consul_config['client_addr'] = ph.finalize_value(cconfig['client_addr'])
end

unless cconfig['advertise_addr'].nil?
  consul_config['advertise_addr'] = ph.finalize_value(cconfig['advertise_addr'])
end

if !ph['consul_node_name'].nil?
  consul_config['node_name'] = ph['consul_node_name']
elsif !cconfig['node_name'].nil?
  consul_config['node_name'] = cconfig['node_name']
end

if !ph['consul_domain'].nil?
  consul_config['domain'] = ph['consul_domain']
elsif !cconfig['domain'].nil?
  consul_config['domain'] = cconfig['domain']
end

if !ph['consul_join'].nil?
  consul_config['start_join'] = ph['consul_join']
elsif !cconfig['join'].nil?
  consul_config['start_join'] = cconfig['join']
end

node.default['consul']['version'] = cconfig['install_version']
node.default['consul']['config'] = consul_config

include_recipe 'consul::default'

if cconfig['update_ufw']
  rule_set = { }

  rule_set['to consul server'] = { 'protocol' => 'tcp',
                                   'port' => '8300' }

  rule_set['to consul serf_lan'] = { 'protocol' => 'tcp',
                                     'port' => '8301' }

  rule_set['to consul serf_wan'] = { 'protocol' => 'tcp',
                                     'port' => '8302' }

  node.default['firewall']['rules'] << rule_set
end
