# Fact: openvswitch ports
#
# Purpose: On any OS - return info about ovs ports for all bridges
#
# Resolution:
#
# Caveats:
require "facter"
require "kernel_modules"
require "set"

module OpenVSwitch
    def self.exec(short, cmd)
        shell_cmd = "/usr/bin/ovs-" + short + "ctl " + cmd
        result = Facter::Util::Resolution.exec(shell_cmd)
        if result
            result = result.split("\n")
        end
        return result
    end

    # vSwitch
    def self.vsctl(cmd)
        return exec("vs", cmd)
    end

    def self.list_br
        return vsctl("list-br")
    end

    def self.list_ports(bridge)
        return vsctl("list-ports " + bridge)
    end

    # OpenFlow
    def self.ofctl(cmd)
        return exec("of", cmd)
    end

    def self.of_show(bridge="")
        return ofctl("show " + bridge)
    end
end


Facter.add("openvswitch_module") do
    setcode do
        Facter.value(:kernel_modules).split(",").include? "openvswitch_mod"
    end
end


if Facter.value(:openvswitch_module) == true
    bridges = OpenVSwitch.list_br

    Facter.add("openvswitch_bridges") do
        setcode do
            bridges.join(",")
        end
    end

    bridges.each do |bridge|
        ports = OpenVSwitch.list_ports(bridge)
        if ports
            Facter.add("openvswitch_ports_#{bridge}") do
                setcode do
                    ports.join(",")
                end
            end
        end
    end
end
