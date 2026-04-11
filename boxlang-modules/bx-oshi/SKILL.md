---
name: bx-oshi
description: Use this skill when accessing OS and hardware information in BoxLang with the bx-oshi module: CPU usage, memory stats, disk space, network info, battery status, process info, and sensor data using getSystemInfo(), getOperatingSystem(), getHardware(), and convenience BIFs.
---

# bx-oshi: OS & Hardware Information

## Installation

```bash
install-bx-module bx-oshi
# CommandBox
box install bx-oshi
```

## Convenience BIFs (Quick Access)

```javascript
// CPU usage over a 1-second interval
cpuPct = getCpuUsage()
cpuPct = getCpuUsage( 2 )   // 2-second measurement interval

// Disk space (path is any directory on the target drive)
freeDisk  = getFreeSpace( "/" )      // bytes
totalDisk = getTotalSpace( "/" )

// Memory
freeOsMem  = getSystemFreeMemory()   // OS free memory in bytes
totalOsMem = getSystemTotalMemory()  // OS total memory in bytes
freeJvm    = getJVMFreeMemory()      // JVM heap free
totalJvm   = getJVMTotalMemory()     // JVM heap total

// Quick display
println( "CPU: #numberFormat( getCpuUsage() * 100, 2 )#%" )
println( "Free RAM: #int( getSystemFreeMemory() / 1024 / 1024 )# MB" )
println( "Free Disk: #int( getFreeSpace( "/" ) / 1024 / 1024 / 1024 )# GB" )
```

## Full System Info via OSHI API

```javascript
// Get the main OSHI entry point
sys = getSystemInfo()

// Operating System
os = getOperatingSystem()
println( os.toString() )             // e.g. "macOS 15.4"
println( os.getManufacturer() )
println( os.getFamily() )
println( os.getVersionInfo().getVersion() )

// Running processes
processes = os.getProcesses()
println( "Running processes: #processes.size()#" )

// Specific process
myProcess = os.getProcess( os.getProcessId() )  // current process
println( "PID: #myProcess.getProcessID()#" )
println( "Memory: #myProcess.getResidentSetSize()# bytes" )
```

## Hardware Information

```javascript
hardware = getHardware()

// CPU
cpu = hardware.getProcessor()
println( "CPU: #cpu.getProcessorIdentifier().getName()#" )
println( "Physical cores: #cpu.getPhysicalProcessorCount()#" )
println( "Logical cores: #cpu.getLogicalProcessorCount()#" )

// Memory (RAM)
mem = hardware.getMemory()
println( "Total RAM: #mem.getTotal() / 1024 / 1024 / 1024# GB" )
println( "Available: #mem.getAvailable() / 1024 / 1024 / 1024# GB" )

// Disks
disks = hardware.getDiskStores()
for ( disk in disks ) {
    println( "#disk.getName()#: #disk.getModel()# (#disk.getSize() / 1073741824# GB)" )
}

// Network interfaces
networks = hardware.getNetworkIFs()
for ( net in networks ) {
    println( "Interface: #net.getName()# - #net.getIPv4addr().toString()#" )
}

// Battery
batteries = hardware.getPowerSources()
for ( battery in batteries ) {
    println( "Battery: #numberFormat( battery.getRemainingCapacityPercent() * 100, 1 )#%" )
    println( "Time remaining: #battery.getTimeRemainingEstimated()# seconds" )
}

// Sensors (temperature, fan speeds)
sensors = hardware.getSensors()
println( "CPU Temp: #sensors.getCpuTemperature()#°C" )
println( "Fan speeds: #sensors.getFanSpeeds().toString()#" )
```

## Health Check Pattern

```javascript
function getSystemHealthReport() {
    return {
        cpuUsage    : getCpuUsage() * 100,
        freeMemGB   : getSystemFreeMemory()  / 1073741824,
        totalMemGB  : getSystemTotalMemory() / 1073741824,
        freeDiskGB  : getFreeSpace( "/" )    / 1073741824,
        totalDiskGB : getTotalSpace( "/" )   / 1073741824,
        jvmFreeGB   : getJVMFreeMemory()     / 1073741824
    }
}
```

## Common Pitfalls

- ✅ Sensor data (temperature, fan speed) is hardware-dependent — not all machines expose it
- ✅ `getCpuUsage()` takes a measurement over an interval — the result is a 0.0–1.0 decimal (multiply by 100 for percentage)
- ❌ Battery info only works on laptops/devices with batteries — will throw on servers without them
- ✅ All paths for `getFreeSpace()`/`getTotalSpace()` should be valid paths on the target disk
