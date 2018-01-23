actions :execute

attribute :title, :kind_of => String, :name_attribute => true
attribute :password, :kind_of => String, :required => true

def initialize(*args)
  super
  @action = :execute
end

action :execute do
  mycnf_path = '/root/.my.cnf'

  root_users = [ "'root'@'localhost'",
                 "'root'@'127.0.0.1'",
                 "'root'@'::1'",
                 "'root'@'%s'" % [ node['hostname'] ],
                 "'root'@'%'" ]

  sql = [ ]
  root_users.each do |ru|
    sql << "CREATE USER IF NOT EXISTS %s IDENTIFIED BY '%s';" % [ ru, password ]
    sql << "SET PASSWORD FOR %s = PASSWORD('%s');" % [ ru, password ]
    sql << "GRANT ALL PRIVILEGES ON *.* TO %s WITH GRANT OPTION;" % ru
  end

  sql << "FLUSH PRIVILEGES;"
  sql = sql.join("\n")

  bash 'mysql_secure_root' do
    user 'root'
    cwd '/root'
    code 'echo "${SQL}" | mysql -h 127.0.0.1'
    environment('SQL' => sql)
    not_if { ::File.exist?(mycnf_path) }
  end

  template mycnf_path do
    user 'root'
    group 'root'
    mode '0600'
    source 'secure_root_my.cnf.erb'
    variables({ :password => password })
    action :create
  end
end
