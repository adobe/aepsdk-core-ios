# Tests Strategy
This document defines different levels of tests are being used in the project. By defining a clear test boundaries, it helps us increase the confidence of code and decrease the overlapping between different tests and in turn will lower the time spent on maintaining the tests.



## Levels

                                                   /\                                
                                                  /  \                               
                                                 /    \                              
                                                /      \                             
                                               / Manual \                            
                                              /  Testing \                           
                                             /            \                          
                                            /--------------\                         
                                           /                \                        
                                          /                  \                       
                                         / Performance Testing\                      
                                        /                      \                     
                                       /------------------------\                    
                                      /                          \                   
                                     /                            \                  
                                    /     Integration Testing      \                 
                                   /                                \                
                                  /----------------------------------\               
                                 /                                    \              
                                /                                      \             
                               /          Funtional Testing             \            
                              /                                          \           
                             ---------------------------------------------\          
                            /                                              \         
                           /                                                \        
                          /                  Unit Testing                    \       
                         /                                                    \      
                        --------------------------------------------------------       



## Unit Testing:

* Should only test a singal method.

* CI will run this test after each code check-in.

* Read more about the best practice for [Unit Test Best Practices](./UnitTestBestPractices.md).

  

## Functional Testing:

* Test a single extension, and treat this extension as a black box.

* Use the testable `ExtensionRuntime` to simulate or mock the interaction with the Event Hub.

* Use the mock `NetworkServices` to monitor or mock the network activities.

* Test input: Simulated incoming events + shared states of other extensions+ network responses 

  Test output: Outgoing events + network requests + shared states

* CI will run this test after each code check-in 

  

## Integration Testing:

* Use the real eventhub but mock `NetworkServices` 
* Focus on: 
    - Happy path of the public APIs.
    - The dependencies between extensions, in particular, the shared states dependency and events dependency.
* CI will run this test after each code check-in 



## Performance Testing:

* Cover memory consumption, memory leak, thread consumption, CPU consumption and execution speed

* Automate the tests for execution speed and run it as part of the integration testing.

  


## Manual Testing:
* Test against production servers.
* Test all the other things couldn't be covered by automation test.
* Should run the test before each release.
* TBD: How to use Griffon?




## Example
TBD.