config = node['bobby']
cabling_config = config['cabling']
cabling_options = cabling_config['options']

home_path = cabling_options['home_path']
user = cabling_options['user']
group = cabling_options['group']

cabling_config.each do |k, vals|
  next if k == 'options'

  app_name = k
  values_path = File.join(home_path, '.cabling_values.%s.yml' % app_name)

  vals = vals.dup
  if vals.include?('.env')
    env_vals = vals.delete('.env')
  else
    env_vals = { }
  end

  template values_path do
    user user
    group group
    mode '0600'

    variables({ :app_name => app_name,
                :values => vals,
                :env => env_vals })

    cookbook 'bobby'
    source 'cabling_values.yml.erb'
    action :create
  end
end
