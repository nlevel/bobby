config = node['bobby']
rconfig = config['ruby']

node.override['rvm']['global_gems'] = [ ]
node.override['rvm']['user_global_gems'] = [ ]

build_packages = [
  'build-essential',
  'libssl-dev',
  'libtool',
  'libcurl4-openssl-dev',
  'libmysqlclient-dev',
  'libxml2-dev',
  'libxslt-dev',
  'libvirt-dev',
  'zlib1g-dev',
  'libreadline6-dev',
  'libyaml-dev',
  'libsqlite3-dev',
  'libgdbm-dev',
  'libffi-dev',
  'ncurses-dev'
]

apt_package build_packages do
  action :install
end

rconfig['users'].each do |user, rvm_config|
  home_path = rvm_config['home_path']

  if rvm_config['group'].nil?
    group = user
  else
    group = rvm_config['group']
  end

  bash 'rvm_gpg_import_%s' % user do
    user user
    group group
    code %{gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3}
    environment({ 'HOME' => home_path })
    action :run
  end

  user_rvm_path = File.join(home_path, '.rvm')
  directory user_rvm_path do
    owner user
    group group
    recursive true
    action :create
  end

  rvm_archives_path = File.join(user_rvm_path, 'archives')
  directory rvm_archives_path do
    owner user
    group group
    recursive true
    action :create
  end

  rvm_archives = rvm_config['archives']
  if !rvm_archives.nil? && !rvm_archives.empty?
    rvm_archives.each do |archive_fname, archive_url|
      archive_path = File.join(rvm_archives_path, archive_fname)

      remote_file archive_path do
        source archive_url
        owner user
        group group
        action :create_if_missing
      end
    end
  end

  rubies = rvm_config['rubies']
  rvm_user_config = {
    'home' => home_path,
    'user' => user,
    'group' => group,
    'version' => rvm_config['rvm_version'] || 'latest',
    'default_ruby' => rvm_config['default_ruby'],
    'rubies' => rubies,
    'rvmrc' => {
      'rvm_max_time_flag' => '20'
    }
  }

  node.default['rvm']['user_installs'] += [ rvm_user_config ]

  include_recipe 'rvm::user'

  starter_gems = rvm_config['starter_gems']
  rubies.each do |ruby_str|
    unless rvm_config['ruby_opts'].nil?
      ruby_opts = rvm_config['ruby_opts'][ruby_str] || { }
    else
      ruby_opts = { }
    end

    all_gems = { }

    starter_gems.each do |gem_name, gem_opts|
      if gem_opts.is_a?(String)
        gem_opts = { :version => gem_opts }
      end

      if gem_opts[:version] == 'latest'
        gem_opts[:version] = nil
      end

      all_gems[gem_name] = gem_opts
    end

    if !ruby_opts['gems'].nil? && !ruby_opts['gems'].empty?
      ruby_opts['gems'].each do |gem_name, gem_opts|
        if gem_opts.is_a?(String)
          gem_opts = { :version => gem_opts }
        end

        if gem_opts[:version] == 'latest'
          gem_opts[:version] = nil
        end

        all_gems[gem_name] = gem_opts
      end
    end

    all_gems.each do |gem_name, gem_opts|
      rvm_gem 'gem_%s_%s_%s' % [ ruby_str, gem_name, user ] do
        user user
        ruby_string ruby_str
        name gem_name
        version gem_opts[:version]
        action :install
      end
    end
  end

  rvm_shell 'rvm_bundle_config_full-index_%s' % user do
    user user
    code 'bundle config full-index true'
    action :run
  end

  bash 'chown_rvm_%s' % user do
    user 'root'
    group 'root'
    code 'sudo find %s ! -user %s -exec chown %s {} \;' % [ user_rvm_path, user, user ]
    action :run
  end
end
