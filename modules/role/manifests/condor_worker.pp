# == Class: role::condor_worker

# Class to track all profiles attached

class role::condor_worker {
  group { 'dockerroot':
    name   => dockerroot,
    ensure => present,
  }
  user { 'condor':
    ensure => present,
    name   => 'condor',
    groups => ['dockerroot'],
  }
  yumrepo{ 'htcondor':
      ensure     => 'present',
      enabled    => true,
      mirrorlist => 'absent',
      descr      => 'HTCondor Development RPM Repository for Redhat Enterprise Linux 7',
      baseurl    => 'https://research.cs.wisc.edu/htcondor/yum/development/rhel7',
      gpgcheck   => false,
  }
  package { 'condor':
    ensure => installed,
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
    content => "{
      \"live-restore\": true,
      \"group\": \"dockerroot\"
      }
      "
  }
  file { '/etc/condor/config.d/49-common':
    ensure  => present,
    content => "CONDOR_HOST = condor-manager.dev.local
  "
  }
  file { '/etc/condor/config.d/51-role-exec':
    ensure  => present,
    content => "use ROLE: Execute
    "
  }
  # address=/0-condor-worker1.dev.local/10.240.0.11
#  address=/1-condor-worker1.dev.local/10.240.0.11

  exec { "echo address=/0-${hostname}.dev.local/${ipaddress_eth0} >> /etc/dnsmasq.conf":
    path => ['/usr/bin'],
  }
  exec { 'echo nameserver 127.0.0.1 >> /etc/resolv.conf':
    path => ['/usr/bin'],
  }

  exec { 'echo 10.240.0.10 condor-manager.dev.local condor-manager >> /etc/hosts':
    path => ['/usr/bin'],
  }
  exec { 'echo 10.46.0.2  spark-master-0.spark-headless.default.svc.cluster.local >> /etc/hosts':
    path => ['/usr/bin'],
  }
  exec { "echo ${ipaddress_eth0} ${hostname}.dev.local >> /etc/hosts":
    path => ['/usr/bin'],
  }

  exec { 'condor_store_cred add -c -p condor':
    path => ['/usr/sbin'],
  }

  service { 'docker':
    ensure  => running,
    enable  => true,
    restart => '',
  }
  service { 'condor':
    ensure  => running,
    enable  => true,
    restart => '',
  }
}
