# == Class: role::centos7_base

# Class to track all profiles attached

class role::centos7_base {
  include profile::sys_base::centos7_base
}
