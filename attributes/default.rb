config = {
  'params' => {
    'loopback_ip' => '127.0.0.1',
    'private_ip' => nil,
    'subnet' => nil,
    'subnet_mask' => nil
  },

  'apt' => {
    'ubuntu_mirror_url' => nil,
    'packages' => [ ],
    'http_proxy' => nil,
    'mariadb_mirror' => false
  },

  'users' => {
    'builtin_users' => 'ubuntu,azureuser,vagrant',
    'admin_groups' => 'sudo,sysadmin,adm,admin,admins,ADMINS',
    'add_users' => [ ]
  },

  'ssh' => {
    'users' => { }
  },

  'dnsmasq' => {
    'listen_address' => '127.0.0.1',
    'servers' => { },
    'host_addresses' => { }
  },

  'openvpn' => {
    'servers' => {

    },

    'clients' => {

    }
  },

  'consul' => {
    'install_version' => '1.5.1'
  },

  'haproxy' => {
    'certs' => { }
  },

  'mysql' => {
    'version' => '5.7.21',
    'bind_address' => '0.0.0.0',
    'bind_port' => 3306,
    'root_password' => '',

    'users' => { },
    'databases' => { }
  },

  'mariadb' => {
    'version' => '10.2',
    'bind_address' => '0.0.0.0',
    'bind_port' => 3306,
    'root_password' => '',

    'users' => { },
    'databases' => { }
  },

  'ruby' => {
    'users' => { }
  },

  'cabling' => {
    'options' => { }
  },

  'ufw' => {

  },

  'pma' => {
    'config' => {
      'version' => '4.7.6',
      'checksum' => 'e460e41c2f74bf7093e3f6d3b762eb97df6e1b346234b4b63bb27fc0d9dcd62c',
      'blowfish_secret' => 'UYMCKL2cVJ0gSe2JrS2oFDBkwH/wR6h2j+fvuePRNBM=',
      'socket' => '/var/run/php/pma-fpm.sock',
    },

    'servers' => { }
  }
}

config['apt']['packages'] += [
  'linux-image-extra-virtual',
  'software-properties-common',
  'apt-transport-https',
  'curl',
  'gnupg-agent',
  'wget',
  'nfs-common',
  'ca-certificates',
  'htop',
  'ufw',
  'traceroute',
  'openssl',
  'ssl-cert',
  'tmux',
  'docker-ce',
  'docker-ce-cli',
  'containerd.io',
  'sqlite3',
  'git-core',
  'emacs-nox',
  'mg',
  'ruby',
  'irb',
  'rake',
  'yarn'
]

default['bobby'] = config
