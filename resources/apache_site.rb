actions :create

attribute :server_name, :kind_of => String, :name_attribute => true
attribute :site_vars, :kind_of => Hash, :required => true
attribute :use_fpm, :kind_of => [ TrueClass, FalseClass ], :default => false
attribute :use_puma, :kind_of => [ TrueClass, FalseClass ], :default => false
attribute :enabled, :kind_of => [ TrueClass, FalseClass ], :default => true

def initialize(*args)
  super
  @action = :create
end

action :create do
  this_site_vars = { 'server_name' => server_name }.merge(site_vars)

  template_path = '%s/sites-available/%s.conf' % [ node['apache']['dir'], server_name ]
  enabled_path = '%s/sites-enabled/%s.conf' % [ node['apache']['dir'], server_name ]

  template template_path  do
    cookbook 'bobby'
    source 'apache_site.conf.erb'
    owner 'root'
    group node['apache']['root_group']
    mode '0644'

    variables(:site_vars => this_site_vars,
              :use_puma => use_puma,
              :use_fpm => use_fpm,
              :server_name => server_name)

    if ::File.exist?(enabled_path)
      notifies :reload, 'service[apache2]', :delayed
    end
  end

  if enabled
    apache_site server_name do
      enable enabled
    end
  end
end
