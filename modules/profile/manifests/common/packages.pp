class profile::common::packages (
    $packages = lookup('packages::installed'),
)
{
  package { $packages:
    ensure => installed,
  }
}
