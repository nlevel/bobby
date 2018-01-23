actions :create

attribute :user, :kind_of => String, :name_attribute => true
attribute :password, :kind_of => String, :required => true
attribute :hosts, :kind_of => String, :default => nil
attribute :privileges, :kind_of => Hash, :default => { }

def initialize(*args)
  super
  @action = :create
end

action :create do
  hosts_a = hosts.split(',')

  hosts_a.each do |host|
    sql = [
      "CREATE USER IF NOT EXISTS '%s'@'%s';" % [ user, host ],
      "SET PASSWORD FOR '%s'@'%s' = PASSWORD('%s');" % [ user, host, password ]
    ]

    privileges.each do |ds, p_info|
      grant_sql = ''

      unless p_info['what'].nil? || p_info['what'].empty?
        grant_sql += 'GRANT %s' % p_info['what']
      else
        grant_sql += 'GRANT USAGE'
      end

      grant_sql += " ON %s TO '%s'@'%s'" % [ ds, user, host ]

      unless p_info['with'].nil? || p_info['with'].empty?
        grant_sql += ' %s' % p_info['with']
      end

      grant_sql += ';'
      sql << grant_sql
    end

    sql << 'FLUSH PRIVILEGES;'

    bash 'mysql_user_%s_%s' % [ user, host ]  do
      user 'root'
      cwd '/root'
      code 'echo "${SQL}" | mysql -h 127.0.0.1'
      environment('SQL' => sql.join("\n"))
    end
  end
end
