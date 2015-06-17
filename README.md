VSwitch
=======

1.1.0 - 2014.2 - Juno

A Puppet module providing things for vSwitches. At the moment OVS is the only
one I've added but please feel free to contribute new providers through
Stackforge. It's based upon types and providers so we can support more then just
OVS or one vSwitch type.

The current layout is:

* bridges - A "Bridge" is basically the thing you plug ports / interfaces into.
* ports - A Port is a interface you plug into the bridge (switch).

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

## TODO:
* OpenFlow controller settings
* OpenFlow Settings
* OpenFlow Tables
* More facts
* Others that are not named here
