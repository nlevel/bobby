config = node['bobby']
dnsmasq_config = config['dnsmasq']

apt_package 'dnsmasq' do
  action :install
end

dnsmasq_conf_path = '/etc/dnsmasq.conf'
dnsmasq_conf_d = '/etc/dnsmasq.d'

[ dnsmasq_conf_d ].each do |d|
  directory d do
    user 'root'
    group 'root'
    recursive true
    action :create
  end
end

dnsmasq_conf_vars = {
  'servers' => { },
  'host_addresses' => { }
}

ph = Bobby::ParamsHelper.new(self)

dnsmasq_conf_vars['listen_address'] =
  ph.finalize_value(dnsmasq_config['listen_address']) || ph['loopback_ip']

dnsmasq_config['host_addresses'].each do |host, h_info|
  next if h_info['skip']

  target_ip = ph.finalize_value(h_info['ip'])
  dnsmasq_conf_vars['host_addresses'][host] = h_info.to_h.merge({ 'ip' => target_ip })
end

dnsmasq_config['servers'].each do |domain, d_info|
  next if d_info['skip']

  dns_server = ph.finalize_value(d_info['dns_server'])
  dnsmasq_conf_vars['servers'][domain] = d_info.to_h.merge({ 'dns_server' => dns_server })
end

dnsmasq_config['servers'].each do |domain, d_info|
  dnsmasq_conf_vars['servers'][domain] = d_info.to_h
end

template dnsmasq_conf_path do
  user 'root'
  group 'root'
  mode '0644'
  source 'dnsmasq.conf.erb'
  variables({ :dnsmasq_conf => dnsmasq_conf_vars,
              :dnsmasq_conf_d => dnsmasq_conf_d })
  notifies :restart, 'service[dnsmasq]'
  action :create
end

service 'dnsmasq' do
  action :nothing
end
