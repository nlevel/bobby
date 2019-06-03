config = node['bobby']
uconfig = config['users']

add_users = [ ]
sudo_users = [ ]

if !uconfig['add_users'].nil? && !uconfig['add_users'].empty?
  uconfig['add_users'].each do |uinfo|
    users_manage uinfo['group_name'] do
      group_id uinfo['group_id']
      data_bag uinfo['data_bag']

      action :create
      notifies :reload, 'ohai[reload_passwd]', :immediately
    end

    add_users += data_bag(uinfo['data_bag'])

    if uinfo['sudo']
      sudo_users += data_bag(uinfo['data_bag'])
    end
  end

  ohai 'reload_passwd' do
    action :nothing
    plugin 'etc'
  end
end

existing_users = uconfig['builtin_users'].split(',').select do |u|
  node['etc']['passwd'][u] ? true : false
end

# Add the currently logged in user, as a sudo, to preserve our sudo powers.
sudo_user = ENV['SUDO_USER']
if !sudo_user.nil? && !sudo_user.empty? && !existing_users.include?(sudo_user)
  existing_users << sudo_user
end

all_sudo_users = existing_users + sudo_users

sudo_groups = node.default['authorization']['sudo']['groups']
sudo_groups += uconfig['admin_groups'].split(',') - sudo_groups
node.default['authorization']['sudo']['groups'] = sudo_groups

node.default['authorization']['sudo']['users'] += all_sudo_users
node.default['authorization']['sudo']['passwordless'] = true

users_custom_commands = [ ]
node.default['authorization']['sudo']['custom_commands']['users'] += users_custom_commands

node.default['authorization']['sudo']['sudoers_defaults'] = [
  '!lecture,tty_tickets,!fqdn',
  'env_reset',
  'mail_badpass',
  'secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"'
]

node.default['authorization']['sudo']['include_sudoers_d'] = true

include_recipe 'sudo'
