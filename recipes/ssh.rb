config = node['bobby']
sconfig = config['ssh']

uconfigs = sconfig['users']

uconfigs.each do |user, uconf|

  ssh_conf = uconf['config']
  unless ssh_conf.nil?
    ssh_conf.each do |ssh_host, ssh_opts|
      ssh_config('%s-%s' % [ user, ssh_host ]) do
        user user
        options 'User' => ssh_opts['user'],
                'HostName' => ssh_opts['ssh_host'],
                'Port' => ssh_opts['ssh_port'],
                'IdentityFile' => ssh_opts['identity_file'] || '~/.ssh/id_rsa',
                'IdentitiesOnly' => 'yes',
                'UserKnownHostsFile' => '/dev/null',
                'StrictHostKeyChecking' => 'no'
        action :add
      end
    end
  end

  auth_keys = uconf['authorized_keys']
  unless auth_keys.nil?
    auth_keys.each do |auth_key|
      ak_info = data_bag_item('auth_keys', auth_key)
      unless ak_info.nil?
        ssh_authorized_keys('%s-%s' % [ user, auth_key ]) do
          user user
          key ak_info['key']
          type ak_info['type']
          comment ak_info['comment']
        end
      end
    end
  end
end
