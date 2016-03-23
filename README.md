VSwitch
=======

4.0.0 - 2016.1 - Mitaka

A Puppet module providing things for vSwitches. At the moment OVS is the only
one I've added but please feel free to contribute new providers through
Stackforge. It's based upon types and providers so we can support more then just
OVS or one vSwitch type.

The current layout is:

* bridges - A "Bridge" is basically the thing you plug ports / interfaces into.
* ports - A Port is a interface you plug into the bridge (switch).
* configs - Configuration settings, if any

## USAGE:
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

## Beaker-Rspec

This module has beaker-rspec tests

To run:

``shell
bundle install
bundle exec rspec spec/acceptance
``

## TODO:
* OpenFlow controller settings
* OpenFlow Settings
* OpenFlow Tables
* More facts
* Others that are not named here
