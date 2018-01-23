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

loopback_ip = config['params']['loopback_ip']
private_ip = config['params']['private_ip']

if dnsmasq_config['listen_address'].nil?
  la = loopback_ip
else
  la = dnsmasq_config['listen_address'].gsub('{private_ip}', private_ip)
end
dnsmasq_conf_vars['listen_address'] = la

dnsmasq_config['host_addresses'].each do |host, h_info|
  target_ip = h_info['ip'].gsub('{private_ip}', private_ip)

  dnsmasq_conf_vars['host_addresses'][host] = h_info.to_h.merge({ 'ip' => target_ip })
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
