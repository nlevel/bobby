config = node['bobby']

pma_config = config['pma']['config']
pma_config.each do |k, v|
  node.set['phpmyadmin'][k] = v
end

# disable FPM support, since we are manually setting this up ourselves.
node.set['phpmyadmin']['fpm'] = false

# additional php5 packages, needed by phpmyadmin
apt_package [ 'php5.6-mcrypt', 'php5.6-mbstring' ] do
  action :install
end

include_recipe 'phpmyadmin'

home_path = node['phpmyadmin']['home']

php_fpm_pool 'pma' do
  action :install

  listen node['phpmyadmin']['socket']
  user node['phpmyadmin']['user']
  group node['phpmyadmin']['group']
end

unless config['pma']['servers'].nil? || config['pma']['servers'].empty?
  config['pma']['servers'].each do |s_key, s_info|
    phpmyadmin_db 'pma_db-%s' % s_key do
      host s_info['host']
      port s_info['port']
      username s_info.fetch('username', '')
      password s_info.fetch('password', '')
      auth_type s_info.fetch('auth_type', 'config')

      unless s_info['hide_dbs'].nil?
        hide_dbs s_info['hide_dbs']
      end
    end
  end
end

[ '.profile', '.bashrc', '.bash_logout' ].each do |f|
  file File.join(home_path, f) do
    action [ :delete ]
  end
end

if node.recipe?('bobby::apache2')
  this_site_vars = {
    'server_name' => node['phpmyadmin']['server_name'],
    'document_root' => home_path,
    'fastcgi_socket' => node['phpmyadmin']['socket']
  }

  bobby_apache_site node['phpmyadmin']['server_name'] do
    site_vars this_site_vars
    use_fpm true

    action :create
  end
elsif node.recipe?('bobby::nginx')
  this_site_vars = {
    'server_name' => node['phpmyadmin']['server_name'],
    'document_root' => home_path,
    'fastcgi_socket' => 'unix:%s' % node['phpmyadmin']['socket']
  }

  bobby_nginx_site node['phpmyadmin']['server_name'] do
    site_vars this_site_vars
    use_fpm true

    action :create
  end
end
