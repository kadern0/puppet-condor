# == Class: role::condor_worker

# Class to track all profiles attached

class role::condor_worker {
  user { 'condor':
    ensure => present,
    name   => 'condor',
    groups => ['dockerroot'],
  }
  #  include profile::sys_base::centos7_base
  exec { 'sudo firewall-cmd --zone=public --add-port=9618/tcp --permanent':
    path => ['/usr/bin'],
  }
  exec { 'sudo firewall-cmd --reload':
    path => ['/usr/bin'],
  }
  exec { 'echo "use ROLE: Execute" | sudo tee -a /etc/condor/config.d/51-role-exec':
    path => ['/usr/bin'],
  }
  file {'/etc/condor/passwords.d':
    ensure => directory,
    mode   => '0700',
  }
  file {'/etc/condor/config.d/50-security':
    ensure  => present,
    content => "
    SEC_PASSWORD_FILE = /etc/condor/passwords.d/POOL
    SEC_DAEMON_AUTHENTICATION = REQUIRED
    SEC_DAEMON_INTEGRITY = REQUIRED
    SEC_DAEMON_AUTHENTICATION_METHODS = PASSWORD
    SEC_NEGOTIATOR_AUTHENTICATION = REQUIRED
    SEC_NEGOTIATOR_INTEGRITY = REQUIRED
    SEC_NEGOTIATOR_AUTHENTICATION_METHODS = PASSWORD
    SEC_CLIENT_AUTHENTICATION_METHODS = FS, PASSWORD, KERBEROS, GSI
    ALLOW_DAEMON = condor_pool@*/*, condor@*/$(IP_ADDRESS)
    ALLOW_NEGOTIATOR = condor_pool@*/condor-manager.dev.local
    "
  }
  file { '/etc/docker/daemon.json':
    ensure  => present,
    content => "
      {
      \"live-restore\": true,
      \"group\": \"dockerroot\"
      }
      "
  }
}
