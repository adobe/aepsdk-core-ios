# Rules Engine

## Overview

A simple, generic, extensible Rules Engine in Swift.


## Installation

### Swift Package Manager

Once you have your Swift package set up, adding RuleEngine as a dependency is as easy as adding it to the dependencies value of your Package.swift.

Example:
```
dependencies: [
.package(url: "https://github.com/adobe/aepsdk-rulesengine-ios.git", from: "0.0.1")
]
```

## Usage


### Initialize Rules Engine

To create a `RuleEngine` instance, first define an `Evaluator` and then use it as the parameter for `RuleEngine`.
```
let evaluator = ConditionEvaluator(options: .caseInsensitive)
let rulesEngine = RulesEngine(evaluator: evaluator)
```

### Define Rules

Any thing that conforms to the `Rule` protocol can be used as rule. The easiest way is to use the built-in `ConsequenceRule`.
```
let condition = ComparisonExpression(lhs: "abc", operationName: "equals", rhs: "abc")
let rule = ConsequenceRule(id: "sample-rule", condition: condition)
rulesEngine.addRules(rules: [rule])
```
However, a rule like this doesn't make much sense, without the ability to dynamically fetch a value it will always be true or false. 

```
let mustache = Operand<String>(mustache: "{{company}}")
let condition = ComparisonExpression(lhs: mustache, operationName: "equals", rhs: "adobe")
let rule = ConsequenceRule(id: "sample-rule", condition: condition)
rulesEngine.addRules(rules: [rule])
```

### Evaluate data

Use the method `evaluate` to run rule engine on the input data that is `Traversable`.

```
let matchedRules = rulesEngine.evaluate(data: ["company":"adobe"])
```



## Contributing

Contributions are welcomed! Read the [Contributing Guide](./.github/CONTRIBUTING.md) for more information.

## Licensing

This project is licensed under the Apache V2 License. See [LICENSE](LICENSE) for more information.
