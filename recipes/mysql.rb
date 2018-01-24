config = node['bobby']
mysql_config = config['mysql']

mysql_service 'default' do
  version mysql_config['version']
  bind_address mysql_config['bind_address']
  port mysql_config['bind_port']
  initial_root_password ''
  action [ :create, :start ]
end

mysql_config 'default_extra' do
  instance 'default'
  cookbook 'bobby'
  source 'mysql_default_extra.cnf.erb'
  notifies :restart, 'mysql_service[default]'
  action :create
end

bobby_mysql_secure_root 'mariadb_secure_root' do
  password mysql_config['root_password']
end

mysql_config['users'].each do |uname, uinfo|
  bobby_mysql_user(uname) do
    password uinfo['password']
    hosts uinfo['hosts']
    privileges uinfo['privileges']
    action :create
  end
end

mysql_config['databases'].each do |dbname, dinfo|
  bobby_mysql_database(dbname) do
    charset dinfo.fetch('charset', 'utf8')
    collate dinfo.fetch('collate', 'utf8_unicode_ci')

    action :create
  end
end
