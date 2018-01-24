config = node['bobby']
mdconfig = config['mariadb']

node.set['mariadb']['install']['version'] = mdconfig['version']
node.set['mariadb']['mysqld']['bind_address'] = mdconfig['bind_address']
node.set['mariadb']['mysqld']['skip_log_bin'] = true
node.set['mariadb']['allow_root_pass_change'] = false

include_recipe 'mariadb::server'

mariadb_configuration 'charset-mysql' do
  section 'mysql'
  option({ :'default-character-set' => 'utf8' })

  notifies :restart, 'service[mysql]', :delayed
end

mariadb_configuration 'charset-client' do
  section 'client'
  option({ :'default-character-set' => 'utf8' })

  notifies :restart, 'service[mysql]', :delayed
end

mariadb_configuration 'charset-mysqld' do
  section 'mysqld'
  option({ :'character-set-server' => 'utf8',
           :'collation-server' => 'utf8_unicode_ci' })

  notifies :restart, 'service[mysql]', :delayed
end

mariadb_configuration 'bind-mysqld' do
  section 'mysqld'
  option({ :'bind-address' =>  mdconfig['bind_address'] })

  notifies :restart, 'service[mysql]', :delayed
end

bobby_mysql_secure_root 'mysql_secure_root' do
  password mdconfig['root_password']
end

mdconfig['users'].each do |uname, uinfo|
  bobby_mysql_user(uname) do
    password uinfo['password']
    hosts uinfo['hosts']
    privileges uinfo['privileges']
    action :create
  end
end

mdconfig['databases'].each do |dbname, dinfo|
  bobby_mysql_database(dbname) do
    charset dinfo.fetch('charset', 'utf8')
    collate dinfo.fetch('collate', 'utf8_unicode_ci')

    action :create
  end
end
