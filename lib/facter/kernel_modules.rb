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
    return File.readlines("/proc/modules").inject(Set.new){|s,l|s << l[/\w+\b/] }
end

modules = get_modules

Facter.add("kernel_modules") do
    setcode do
        modules.to_a.join(",")
    end
end
