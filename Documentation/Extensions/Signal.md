# Signal Extension

The Signal extension handles three types of event - postback, PII and open url. For postback and PII requests, it adds the requests to the data queue and then sends out the HTTP requests in the order. It relies on `AEPServcies`'s `URLOpening` service to deal with the open url request.

## Workflow

![Signal Workflow](https://lucid.app/publicSegments/view/f88e1486-28b6-4f41-988d-0bb8b13a64c2/image.png)

## Rules Engine
All the postback, PII and open url requests are triggered by the rules engine which is configured with launch UI rules. For more infomation about rules engine, refer to [link].
