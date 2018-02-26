actions :create

attribute :server_name, :kind_of => String, :name_attribute => true
attribute :site_vars, :kind_of => Hash, :required => true
attribute :use_fpm, :kind_of => [ TrueClass, FalseClass ], :default => false
attribute :use_proxy_pass, :kind_of => [ TrueClass, FalseClass ], :default => false
attribute :use_puma, :kind_of => [ TrueClass, FalseClass ], :default => false
attribute :enabled, :kind_of => [ TrueClass, FalseClass ], :default => true

def initialize(*args)
  super
  @action = :create
end

action :create do
  this_site_vars = { 'server_name' => server_name }.merge(site_vars)

  if use_puma
    self.use_proxy_pass = true
    this_site_vars['proxy_port'] = this_site_vars.fetch('puma_port', 3000)
  end

  if this_site_vars['proxy_rewrites'].is_a?(Hash)
    rw_a = this_site_vars['proxy_rewrites']
    this_site_vars['proxy_rewrites'] = rw_a.keys.sort.collect { |k| rw_a[k] }
  end

  nginx_site server_name do
    variables(:site_vars => this_site_vars,
              :use_proxy_pass => use_proxy_pass,
              :use_fpm => use_fpm,
              :server_name => server_name)

    cookbook 'bobby'
    template 'nginx_site.conf.erb'
    enable enabled
  end
end
