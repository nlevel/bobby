private_ip = nil

# try to pick the first ip, from the list of interfaces

node['network']['interfaces'].each do |i_name, i_info|
  next unless i_info['encapsulation'] == 'Ethernet'

  inet_addr = i_info['addresses'].keys.detect do |ip|
    i_info['addresses'][ip]['family'] == 'inet'
  end

  unless inet_addr.nil?
    private_ip = inet_addr
    break
  end
end

node.default['bobby']['params']['private_ip'] = private_ip
