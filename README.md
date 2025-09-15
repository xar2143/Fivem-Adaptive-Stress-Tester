# FiveM Adaptive Stress Tester

A powerful, server-side only module for running **automatic adaptive stress tests** on your FiveM server. Ideal for developers and server administrators who want to validate stability, performance and resilience under load.

> **DISCLAIMER**: This script can significantly impact CPU, RAM and network. **Do not run on production servers or without permission.** Use only in controlled test/development environments.

---

## Features

* **Adaptive Load**: Detects available RAM and CPU in real time and adjusts test intensity automatically.
* **Event Simulation**: Fires thousands of fake server events.
* **Database Simulation**: Generates and sorts dummy data to simulate DB operations.
* **HTTP Requests**: Issues concurrent HTTP calls (limited by config).
* **Real-Time Monitoring**: Periodic progress reports to console.
* **Detailed Report**: Prints a summary report at test end.

---

## Configuration (inside the Lua script)

```lua
local Config = {
    maxDuration        = 60000,  -- maximum test duration in ms (default: 60s)
    minDelay           = 50,     -- minimum delay between cycles (ms)
    maxDelay           = 500,    -- maximum delay between cycles (ms)
    memoryThreshold    = 0.8,    -- stop if memory usage exceeds 80%
    cpuThreshold       = 0.9,    -- stop if CPU usage exceeds 90%
    maxConcurrentHttp  = 5,      -- max simultaneous HTTP requests
    reportInterval     = 10000   -- how often to print progress (ms)
}
```

---

## Commands & Usage

### Start Test

* **Default duration (60 s):**

  ```
  /stresstest start
  ```
* **Custom duration (in seconds):**

  ```
  /stresstest start [seconds]
  ```

  *Example:* `/stresstest start 120` → 2-minute test.

### Stop Test

* **Manually end test before timeout:**

  ```
  /stresstest stop
  ```

### Console Output Examples

#### During Test

```
[STRESS TEST] Progress: 12.4s | Events: 620 | HTTP: 4 | Threads: 12 | Memory: 284.7MB | CPU Est: 55.0%
```

#### End-of-Test Report

```
========================================
         STRESS TEST REPORT
========================================
Test Duration:       60.00 seconds
Total Events:        1800
Total HTTP Requests: 180
Events per Second:   30.00
HTTP per Second:     3.00
Average Event Time:  1.67 ms
Max Active Threads:  35
Final Memory Usage:  290.2 MB
Final CPU Load:      58.0%
========================================
```

---

## Simulated Operations

| Operation Type         | Description                         |
| ---------------------- | ----------------------------------- |
| `stress:testEvent`     | Generic server event                |
| `stress:playerAction`  | Simulated player interaction        |
| `stress:serverEvent`   | Heavy server-side computation       |
| `stress:databaseQuery` | Dummy database read/sort operations |
| `stress:networkEvent`  | Fake network payload & HTTP calls   |

---

## ⚠️ Important Notes

* **Do not** use on live/production servers.
* The script **does not** spawn NPCs or vehicles—only simulates logic and I/O load.
* Always run in a **safe test environment**.
