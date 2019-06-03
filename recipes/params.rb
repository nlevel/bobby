require 'ipaddr'

private_ip = nil
default_gw = nil
subnet = nil
subnet_mask = nil

# try to pick the first ip, from the list of interfaces

node['network']['interfaces'].each do |i_name, i_info|
  next unless i_info['encapsulation'] == 'Ethernet'

  inet_addr = i_info['addresses'].keys.detect do |ip|
    i_info['addresses'][ip]['family'] == 'inet'
  end

  unless inet_addr.nil?
    ia_info = i_info['addresses'][inet_addr]

    private_ip = inet_addr
    subnet_mask = ia_info['netmask']
    subnet = (IPAddr.new(private_ip) & subnet_mask).to_s

    break
  end
end

node.default['bobby']['params'] = {
  'private_ip' => private_ip,
  'default_gw' => default_gw,
  'subnet' => subnet,
  'subnet_mask' => subnet_mask
}
