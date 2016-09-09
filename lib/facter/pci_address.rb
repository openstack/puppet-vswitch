require 'facter'
drivers_details=Facter::Util::Resolution.exec("cat /proc/bus/pci/devices")
drivers_lines=drivers_details.split("\n")
drivers=Hash.new
drivers_lines.each do |line|
  line = line.gsub(/^\s+|\s+$/m, '').split(" ")
  if line.length == 18
    pci_embed = line[0]
    driver = line[-1]
    bus = pci_embed[0] + pci_embed[1]
    dev = ((pci_embed[2].to_i(16) << 1) + (pci_embed[3].to_i(16) >> 3)).to_s(16).rjust(2,"0").upcase
    fun = (pci_embed[3].to_i(16) & 7).to_s(16).upcase
    pci = "0000:" + bus + ":" + dev + "." + fun
    if not drivers.has_key?(driver)
      drivers[driver] = Array.new
    end
    drivers[driver] << pci
  end
end

drivers.each do |driver,pci_addr|
  Facter.add("pci_address_driver_#{driver}") do
    confine :kernel => :linux
    setcode do
      pci_addr.join(',')
    end
  end
end
