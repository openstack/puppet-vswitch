# Fact: kmod_*
#
# Purpose: Provide facts about loaded and configured modules
#
# Resolution:
#
# Caveats:

require "facter"
require "set"

def get_modules
    if File.exists?("/proc/modules")
        return File.readlines("/proc/modules").inject(Set.new){|s,l|s << l[/\w+\b/] }
    end
end

modules = get_modules

Facter.add("kernel_modules") do
    confine :kernel => :linux
    setcode do
        modules.to_a.join(",")
    end
end
