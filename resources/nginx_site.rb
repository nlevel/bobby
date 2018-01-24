actions :create

attribute :server_name, :kind_of => String, :name_attribute => true
attribute :site_vars, :kind_of => Hash, :required => true
attribute :use_fpm, :kind_of => [ TrueClass, FalseClass ], :default => false
attribute :use_puma, :kind_of => [ TrueClass, FalseClass ], :default => false

def initialize(*args)
  super
  @action = :create
end

action :create do
  this_site_vars = { 'server_name' => server_name }.merge(site_vars)

  nginx_site server_name do
    variables(:site_vars => this_site_vars,
              :use_puma => use_puma,
              :use_fpm => use_fpm)

    cookbook 'bobby'
    template 'nginx_site.conf.erb'
    enable true
  end
end
