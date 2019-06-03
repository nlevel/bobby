name 'bobby'
maintainer 'Next Level'
maintainer_email 'mark@nlevel.io'
license 'all_rights'
description 'Installs/Configures bobby'
long_description 'Installs/Configures bobby'
version '0.2.0'

# The `issues_url` points to the location where issues for this cookbook are
# tracked.  A `View Issues` link will be displayed on this cookbook's page when
# uploaded to a Supermarket.
#
# issues_url 'https://github.com/<insert_org_here>/bobby/issues' if respond_to?(:issues_url)

# The `source_url` points to the development reposiory for this cookbook.  A
# `View Source` link will be displayed on this cookbook's page when uploaded to
# a Supermarket.
#
# source_url 'https://github.com/<insert_org_here>/bobby' if respond_to?(:source_url)

depends 'apt'
depends 'build-essential'
depends 'openssh'
depends 'java'
depends 'docker'
depends 'openssh'
depends 'sudo'
depends 'cacert'
depends 'users'
depends 'openvpn'
depends 'ssh'
depends 'ufw'
depends 'mysql'
depends 'mariadb'
depends 'php'
depends 'apache2'
depends 'nginx'
depends 'phpmyadmin'
depends 'nodejs'
depends 'consul'
depends 'squid'
depends 'haproxy'
