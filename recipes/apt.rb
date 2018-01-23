config = node['bobby']
apt_config = config['apt']

if !apt_config['http_proxy'].nil? && !apt_config['http_proxy'].empty?
  apt_http_proxy = apt_config['http_proxy']

  file '/etc/apt/apt.conf.d/01apt_proxy.conf' do
    user 'root'
    group 'root'
    content "Acquire::http::proxy \"%s\";
Acqu        ire::https::proxy \"%s\";" % [ apt_http_proxy, apt_http_proxy ]
    mode 0644
    action :create
  end
end

apt_repository 'docker' do
  uri 'https://apt.dockerproject.org/repo'
  distribution '%s-%s' % [ node['platform'], node['lsb']['codename'] ]
  components [ 'main' ]
  key '58118E89F3A912897C070ADBF76221572C52609D'
end

apt_repository 'php' do
  uri 'http://ppa.launchpad.net/ondrej/php/ubuntu'
  distribution node['lsb']['codename']
  components [ 'main' ]
  keyserver 'keyserver.ubuntu.com'
  key 'E5267A6C'
end

apt_repository 'nodejs' do
  uri 'https://deb.nodesource.com/node_9.x'
  distribution node['lsb']['codename']
  components [ 'main' ]
  key 'https://deb.nodesource.com/gpgkey/nodesource.gpg.key'
end

apt_repository 'yarn' do
  uri 'https://dl.yarnpkg.com/debian/'
  distribution 'stable'
  components [ 'main' ]
  key 'https://dl.yarnpkg.com/debian/pubkey.gpg'
end

apt_repository 'nginx' do
  uri 'https://nginx.org/packages/ubuntu'
  distribution node['lsb']['codename']
  components %w(nginx)
  deb_src true
  key 'https://nginx.org/keys/nginx_signing.key'
end

if apt_config['mariadb_mirror']
  apt_repository 'mariadb' do
    uri 'http://sfo1.mirrors.digitalocean.com/mariadb/repo/10.2/ubuntu'
    distribution '%s' % node['lsb']['codename']
    components [ 'main' ]
    keyserver 'keyserver.ubuntu.com'
    key '0xF1656F24C74CD1D8'
  end
end

unless apt_config['ubuntu_mirror_url'].nil?
  template '/etc/apt/sources.list' do
    user 'root'
    group 'root'
    mode '0644'
    source 'sources.list.erb'
    variables({ :ubuntu_mirror_url => apt_config['ubuntu_mirror_url'] })
    notifies :run, 'execute[apt-get update]', :immediately
    action :create
  end
end

include_recipe 'apt::default'

execute 'dpkg_configure' do
  command '/usr/bin/dpkg --configure -a'
end

apt_package apt_config['packages'] do
  action :install
end
