Stocks
======
[![v0.6](https://img.shields.io/badge/download-v0.6-brightgreen.svg)](https://github.com/arbitrary-dev/stocks/releases/download/v0.6/stocks-0.6.zip)

When you are a fancy aspiring guy who wants to track his stocks prices…

![screenshot](https://github.com/arbitrary-dev/stocks/raw/master/screenshot.png "screenshot")

## Configuration

Just create `~/.stocks` with your favorites:

```
AAPL:
  market : nasdaq

FAG:
  market : nasdaqomxnordic
  id     : SSE903
```

## Supported markets

- ~~`nasdaq` – [Nasdaq](https://www.nasdaq.com)~~ broken :'(
- `nasdaqomxnordic` – [Nasdaq for nordic markets](http://www.nasdaqomxnordic.com)  
  To retrieve `id` for stock just lookup `Instrument` query parameter from URL
  address.
