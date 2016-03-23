## 4.0.0 and beyond

From 4.0.0 release and beyond, release notes are published on
[docs.openstack.org](http://docs.openstack.org/releasenotes/puppet-vswitch/).

##2015-11-25 - 3.0.0
###Summary

This is a major release for OpenStack Liberty but contains no API-breaking
changes.


####Features
- support for FreeBSD

###Bugfixes
- explicitly say that ovs_redhat parent is ovs
- add require ovs_redhat.rb to ovs_redhat_el6.rb

####Maintenance
- acceptance: use common bits from puppet-openstack-integration
- remove class_parameter_defaults puppet-lint check
- fix RSpec 3.x syntax
- initial msync run for all Puppet OpenStack modules

##2015-10-15 - 2.1.0
###Summary

This is a maintainence release in the Kilo series.

####Maintenance
- acceptance: checkout stable/kilo puppet modules


##2015-07-08 - 2.0.0
###Summary

This is a major release for OpenStack Kilo but contains no API-breaking
changes.


####Features
- Puppet 4.x support
- make dkms on Debian/Ubuntu optional

####Maintenance
- Acceptance tests with Beaker
- Fix spec tests for RSpec 3.x and Puppet 4.x
