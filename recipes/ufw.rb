config = node['bobby']
ufw = config['ufw']

include_recipe 'ufw::default'
