actions :create

attribute :dbname, :kind_of => String, :name_attribute => true
attribute :charset, :kind_of => String, :required => true
attribute :collate, :kind_of => String, :required => true

def initialize(*args)
  super
  @action = :create
end

action :create do
  sql = [
    "CREATE DATABASE IF NOT EXISTS `%s` CHARACTER SET='%s' COLLATE='%s';" % [ dbname, charset, collate ]
  ]

  bash 'mysql_database_%s' % [ dbname ]  do
    user 'root'
    cwd '/root'
    code 'echo "${SQL}" | mysql -h 127.0.0.1'
    environment('SQL' => sql.join("\n"))
  end
end
