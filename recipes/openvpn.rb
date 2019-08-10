this_config = node['bobby']
oconfig = this_config['openvpn']

OPENVPN_PATH = '/etc/openvpn'
CERTS_SUBPATH = 'keys'
CERTS = [ 'ca', 'dh', 'cert', 'key', 'tls-auth' ]

DEFAULT_SERVER_CONFIG = {
  'client-to-client' => '',
  'keepalive' => '10 120',
  'comp-lzo' => 'adaptive',
  'persist-key' => '',
  'persist-tun' => '',
  'verb' => '3',
  'port' => '1194',
  'proto' => 'udp',
  'dev' => 'tun',
  'duplicate-cn' => ''
}

DEFAULT_CLIENT_CONFIG = {
  'client' => '',
  'dev' => 'tun',
  'proto' => 'udp',
  'port' => '1194',
  'resolv-retry' => 'infinite',
  'nobind' => '',
  'persist-key' => '',
  'persist-tun' => '',
  'comp-lzo' => 'adaptive',
  'verb' => '3',
  'pull' => '',
  'float' => '',
  'keepalive' => '10 60'
}

# disable default server, and we manually create the servers ourselves.
node.override['openvpn']['configure_default_server'] = false

include_recipe 'openvpn::default'
include_recipe 'openvpn::enable_ip_forwarding'

sysctl 'net.ipv4.ip_forward' do
  value 1
end

sysctl 'net.ipv6.conf.default.forwarding' do
  value 1
end

sysctl 'net.ipv6.conf.all.forwarding' do
  value 1
end

ovpn_path = oconfig['path'] || OPENVPN_PATH
certs_path = File.join(ovpn_path, CERTS_SUBPATH)

directory certs_path do
  user 'root'
  group 'root'
  recursive true
  action :create
end

ph = Bobby::ParamsHelper.new(self)

servers = oconfig['servers']
servers.each do |s_name, s_config|
  next unless s_config['enable']

  ovpn_config = DEFAULT_SERVER_CONFIG.merge(s_config)
  ovpn_config.delete('enable')
  ovpn_config.delete('update_ufw')

  ovpn_proutes = ovpn_config.delete('push_routes') || [ ]
  ovpn_proutes = ovpn_proutes.collect { |pr| ph.finalize_value(pr) }

  ovpn_poptions = ovpn_config.delete('push_options') || [ ]
  ovpn_poptions = ovpn_poptions.collect { |pr| [ pr[0], ph.finalize_value(pr[1]) ] }

  vpn_subnet, vpn_subnet_mask = ovpn_config['server'].split(' ')

  CERTS.each do |cert_k|
    cert_k_indb = ovpn_config[cert_k]

    unless cert_k_indb.nil?
      if cert_k_indb.is_a?(Array)
        cert_k_indb, cert_k_extras = cert_k_indb
      else
        cert_k_extras = nil
      end

      cert_info = data_bag_item('certs', cert_k_indb)
      unless cert_info.nil?
        cert_fname = File.join(certs_path, cert_info['fname'])
        file cert_fname do
          content cert_info['content']
          user 'root'
          group 'root'
          mode '0600'
          action :create
        end

        ovpn_config[cert_k] = '%s/%s' % [ CERTS_SUBPATH, cert_info['fname'] ]
        unless cert_k_extras.nil?
          ovpn_config[cert_k] += ' %s' % cert_k_extras
        end
      else
        raise "Cert with key '%s' not found in databag" % cert_k_indb
      end
    end
  end

  unless ovpn_config['client-config-dir'].nil?
    ccd_path = File.join(ovpn_path, ovpn_config['client-config-dir'])

    directory ccd_path do
      user 'root'
      group 'root'
      recursive true
      action :create
    end

    unless ovpn_config['client-config'].nil?
      ovpn_config['client-config'].each do |sc_key, sc_config|
        if sc_config.is_a?(Array)
          sc_config = sc_config.join("\n")
        end

        sc_config_fname = File.join(ccd_path, sc_key)
        file sc_config_fname do
          content sc_config
          user 'root'
          group 'root'
          mode '0644'
          action :create
        end
      end

      ovpn_config.delete('client-config')
    end
  end

  openvpn_conf s_name do
    config ovpn_config
    push_routes ovpn_proutes
    push_options ovpn_poptions

    action :create
    notifies :reload, 'systemd_unit[openvpn]', :immediately
  end

  service 'openvpn@%s' % s_name do
    subscribes :restart, 'openvpn_conf[%s]' % s_name, :delayed
    action :nothing
  end

  if s_config['update_ufw']
    rule_set = { }

    rule_set['from %s' % s_name] =
      { 'protocol' => 'none',
        'source' => '%s/%s' % [ vpn_subnet, vpn_subnet_mask ] }

    rule_set['to %s' % s_name] =
      { 'protocol' => 'none',
        'destination' => '%s/%s' % [ vpn_subnet, vpn_subnet_mask ] }

    node.default['firewall']['rules'] << rule_set
  end
end

clients = oconfig['clients']
clients.each do |c_name, c_config|
  next unless c_config['enable']

  ovpn_config = DEFAULT_CLIENT_CONFIG.merge(c_config)
  ovpn_config.delete('enable')
  ovpn_config.delete('update_ufw')
  ovpn_config.delete('auth-username')
  ovpn_config.delete('auth-password')

  ovpn_routes = ovpn_config.delete('route') || [ ]
  unless ovpn_routes.empty?
    ovpn_config['route'] = ovpn_routes.collect { |pr| ph.finalize_value(pr) }
  end

  CERTS.each do |cert_k|
    cert_k_indb = ovpn_config[cert_k]

    unless cert_k_indb.nil?
      if cert_k_indb.is_a?(Array)
        cert_k_indb, cert_k_extras = cert_k_indb
      else
        cert_k_extras = nil
      end

      cert_k_indb, cert_params = cert_k_indb.split(' ', 2)
      cert_info = data_bag_item('certs', cert_k_indb)

      unless cert_info.nil?
        cert_fname = File.join(certs_path, cert_info['fname'])
        file cert_fname do
          content cert_info['content']
          user 'root'
          group 'root'
          mode '0600'
          action :create
        end

        ovpn_config[cert_k] = '%s/%s' % [ CERTS_SUBPATH, cert_info['fname'] ]
        unless cert_k_extras.nil?
          ovpn_config[cert_k] += ' %s' % cert_k_extras
        end

        if !cert_params.nil?
          ovpn_config[cert_k] = '%s %s' % [ ovpn_config[cert_k], cert_params ]
        end
      else
        raise "Cert with key '%s' not found in databag" % cert_k_indb
      end
    end
  end

  if !c_config['auth-username'].nil? || !c_config['auth-username'].empty?
    auth_username = c_config['auth-username']
    auth_password = c_config['auth-password'] || ''

    secrets_path = File.join(OPENVPN_PATH, '%s.auth_secrets' % c_name)

    file secrets_path do
      content "%s\n%s" % [ auth_username, auth_password ]
      user 'root'
      group 'root'
      mode '0600'
      action :create
    end

    ovpn_config['auth-user-pass'] = File.basename(secrets_path)
  end

  openvpn_conf c_name do
    config ovpn_config

    action :create
    notifies :reload, 'systemd_unit[openvpn]', :immediately
  end

  service 'openvpn@%s' % c_name do
    subscribes :restart, 'openvpn_conf[%s]' % c_name, :delayed
    action :nothing
  end
end

systemd_unit 'openvpn' do
  action :nothing
end
