php_config = {
  'conf_dir' => '/etc/php/5.6/cli',
  'ext_conf_dir' => '/etc/php/5.6/conf.d',

  'src_deps' => %w(libbz2-dev libc-client2007e-dev libcurl4-gnutls-dev libfreetype6-dev libgmp3-dev libjpeg62-dev libkrb5-dev libmcrypt-dev libpng12-dev libssl-dev libt1-dev libxml2-dev libxslt-dev zlib1g-dev),

  'packages' => %w(php5.6 php5.6-dev php5.6-cgi php5.6-cli php-pear),

  'mysql' => { 'package' => 'php5.6-mysql' },
  'sqlite' => { 'package' => 'php5.6-sqlite3' },
  'curl' => { 'package' => 'php5.6-curl' },
  'gd' => { 'package' => 'php5.6-gd' },
  'ldap' => { 'package' => 'php5.6-ldap' },
  'pgsql' => { 'package' => 'php5.6-pgsql' },

  'fpm_package' => 'php5.6-fpm',
  'fpm_pooldir' => '/etc/php/5.6/fpm/pool.d',
  'fpm_default_conf' => '/etc/php/5.6/fpm/pool.d/www.conf',
  'fpm_service' => 'php5.6-fpm',
  'fpm_socket' => '/var/run/php/php5.6-fpm.sock',

  'enable_mod' => '/usr/sbin/phpenmod',
  'disable_mod' => '/usr/sbin/phpdismod',
}

node.default['php'].update(php_config)
node.default['php']['packages'].replace(php_config['packages'])

include_recipe 'php'
include_recipe 'php::module_curl'
include_recipe 'php::module_gd'
include_recipe 'php::module_mysql'
include_recipe 'php::module_sqlite3'

# additional packages by requests
# please be frugal, to avoid bloating
package [ 'php5.6-xmlrpc', 'php5.6-xml', 'php5.6-zip' ] do
  action :install
end

php_fpm_pool 'default' do
  action :install
end

if node.recipe?('bobby::apache2')
  apache_config 'php5.6-cgi' do
    enable :true
  end

  apache_config 'php5.6-fpm' do
    enable :true
  end
end
