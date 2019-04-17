Team and repository tags
========================

[![Team and repository tags](https://governance.openstack.org/tc/badges/puppet-vswitch.svg)](https://governance.openstack.org/tc/reference/tags/index.html)

<!-- Change things from this point on -->

VSwitch
====

#### Table of Contents

1. [Overview - What is the AODH module?](#overview)
2. [Development - Guide for contributing to the module](#development)
3. [Contributors - Those with commits](#contributors)
4. [Release Notes - Release notes for the project](#release-notes)
5. [Repository - The project source code repository](#repository)
6. [Usage - The usage of the module](#usage)
7. [Beaker-Rspec - Beaker-rspec tests for the project](#beaker-rpsec)
8. [TODO - What to do next](#todo)

Overview
--------

4.0.0 - 2016.1 - Mitaka

A Puppet module providing things for vSwitches. At the moment OVS is the only
one I've added but please feel free to contribute new providers through
Stackforge. It's based upon types and providers so we can support more then just
OVS or one vSwitch type.

The current layout is:

* bridges - A "Bridge" is basically the thing you plug ports / interfaces into.
* ports - A Port is a interface you plug into the bridge (switch).
* configs - Configuration settings, if any

Development
-----------

Developer documentation for the entire puppet-openstack project.

* https://docs.openstack.org/puppet-openstack-guide/latest/

Contributors
------------

* https://github.com/openstack/puppet-vswitch/graphs/contributors

Release Notes
-------------

* https://docs.openstack.org/releasenotes/puppet-vswitch

Repository
-------------

* https://git.openstack.org/cgit/openstack/puppet-vswitch

Usage
-------------
To create a new bridge, use the `vs_bridge` type:

```
vs_bridge { 'br-ex':
  ensure => present,
}
```

You can then attach a device to the bridge with a virtual port:
```
vs_port { 'eth2':
  ensure => present,
  bridge => 'br-ex',
}
```

You can change the vswitch configuration settings using.
```
vs_config { 'parameter_name':
  ensure => present,
  value => "some_value"
}
```
For configuration parameters that are 'hash' data type, the resource name
should be of the following format

```
parameter-name:key-name

Ex.
vs_config { 'external_ids:ovn-remote':
  ensure => present,
  value => 'tcp:127.0.0.1:6640'
}
```

For 'set/array' data types, value should be in the following format

```
'[<values>]'

Ex.
vs_config { 'array_key':
  ensure => present,
  value => '[2, 1, 6, 4]'
}
```

Beaker-Rspec
-------------

This module has beaker-rspec tests

To run:

```shell
bundle install
bundle exec rspec spec/acceptance
```

TODO:
-------------
* OpenFlow controller settings
* OpenFlow Settings
* OpenFlow Tables
* More facts
* Others that are not named here
