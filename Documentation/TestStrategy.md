# Testing Strategy

This document defines different levels of tests being used by modules in this repository. By defining clear test boundaries, it helps increase confidence in the code and decrease overlap between different kinds of tests. This will lower the required time spent to maintain tests.

## Testing Levels

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
                               /          Functional Testing            \            
                              /                                          \           
                             ---------------------------------------------\          
                            /                                              \         
                           /                                                \        
                          /                  Unit Testing                    \       
                         /                                                    \      
                        --------------------------------------------------------       



## Unit Testing

* CI will run unit tests after each code check-in.

* Should only test a single method.

* Read more about [Unit Testing Best Practices](./UnitTestBestPractices.md).

## Functional Testing

* CI will run functional tests after each code check-in.

* Black box tests for a single extension.

* Use the testable `ExtensionRuntime` to simulate or mock interactions with the Event Hub.

* Use the mock `NetworkServices` to monitor or mock network activities.

* Test input: Simulated incoming events + shared states of other extensions + network responses

* Test output: Outgoing events + network requests + shared states

## Integration Testing

* CI will run integration tests after each code check-in.

* Use the real `eventhub`, but mock `NetworkServices`.

* Focus on:

    - Happy path of the public APIs.

    - Dependencies between extensions. In particular, shared state and event dependencies.

## Performance Testing

* Cover memory consumption, memory leaks, thread consumption, CPU consumption and execution speed.

* Automate tests for execution speed and run them as part of the integration testing.

## Manual Testing

* Test with production-ready code against production servers.

* Test anything that cannot be covered by automated tests.

* Should be run before each release.
