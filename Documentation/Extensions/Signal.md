# Signal Extension

The Signal extension handles three types of event - postback, PII and open url. For postback and PII requests, it adds the requests to the data queue and then sends out the HTTP requests in the order. It relies on `AEPServcies`'s `URLOpening` service to deal with the open url request.

## Workflow

![Signal Workflow](https://lucid.app/publicSegments/view/f88e1486-28b6-4f41-988d-0bb8b13a64c2/image.png)



## Rules Engine
For PII request, it can be triggered by either the public `AEPCore.collectPii` method or by the rules engine with launch UI rules. For postback and open url requests, they are mostly triggered by the rules engine.
For more infomation about rules engine, refer to [link].
