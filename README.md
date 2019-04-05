Stocks
======
[![v0.5](https://img.shields.io/badge/download-v0.5-brightgreen.svg)](https://github.com/arbitrary-dev/stocks/releases/download/v0.5/stocks-0.5.app.zip)

When you are a fancy aspiring guy who wants to track his stocks prices…

Just create `~/.stocks` with your favorite stocks:
```
AAPL:
  market : nasdaq

FAG:
  market : nasdaqomxnordic
  id     : SSE903
```

Markets supported:
- `nasdaq` – [Nasdaq](https://www.nasdaq.com)
- `nasdaqomxnordic` – [Nasdaq for nordic markets](http://www.nasdaqomxnordic.com)  
  To retrieve `id` for stock just lookup `Instrument` query parameter from URL
  address.
