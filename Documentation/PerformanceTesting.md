# Performance Testing

This document provides details about how to collect AEP SDK core components' performance data. To avoid potential performance problems, usually all (or part) of the following steps need to be executed before each core SDK release.

# Test Setup

- Connect an iphone device to your Mac machine
- Open an Xcode project from [here](https://github.com/adobe/aepsdk-core-ios/tree/main/TestApp%20), then you will see two targets (`PerformanceApp` and `PerformanceTests`) in the project
- Run above two targets manually on the iphone device to collect the following performance data

# Performance Metric

- ### Execution Time

  - Run `PerformanceTests` target 
  - Then the test result will show the execution time of `loading all SDK core conponents` and `evaluating 1000 rules in Rules Engine`

- ### Memory Consumption/Thread Consumption/CPU Consumption

  - Launch the `PerformanceApp` and open the `debug navigation` view from Xcode.
  - Then click the buttons (`Load AEP SDK` and `Evaluate Rules`) on the App, and at the same time check the memory usage/ thead comsumption and CPU usage from Xcode.

- ### Memory Leak

  - Launch the `PerformanceApp` and open the `debug navigation` view from Xcode.
  - Go to `debug navigation` view and select the `Memory` catagory, then click the button `Profile in Instruments` from the right side.
  - Then the `Instruments` tool will show the memory `Allocations` and `Leaks`. if the UI show the green icons, it indicates the test app doesn't have any memory leaks. 

# Performance Baseline 

  - Execution Time
    - `loading all SDK core conponents`       < 2s
    - `evaluating 1000 rules in Rules Engine` < 2s
  - Memory Consumption
    - `loading all SDK core conponents`       < 3M
    - `evaluating 1000 rules in Rules Engine` < 30M
  - Thread Consumption
    - `loading all SDK core conponents`       < 10
    - `evaluating 1000 rules in Rules Engine` ≈ 20-25
    
    
    
    
    
