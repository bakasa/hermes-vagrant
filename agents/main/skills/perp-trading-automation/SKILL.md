# ============================================================================
# Perpetual Trading Automation Skill
# ============================================================================
# Governs how OWL interacts with and monitors the perpetual futures
# trading bot system (perp-trading-bot).
# ============================================================================

---

## Scope

This skill covers:
- Monitoring trading bot health and performance
- Interpreting trade signals and bot decisions
- Configuring trading parameters
- Risk management controls
- Report generation for trading performance

## Trading System Architecture

```
MARKET DATA → SIGNAL ENGINE → RISK CHECK → ORDER EXECUTION → POSITION MANAGEMENT
                  │                               │
                  └──── Feedback Loop ────────────┘
```

- **perp-trading-bot**: Core trading engine at `/data/workspace/perp-trading-bot`
- **Paper Trading**: Simulated trading mode (testnet)
- **Live Trading**: Real capital (requires explicit user authorization)
- **Logs**: `/data/workspace/perp-trading-bot/testnet_logs/`

## Operational Modes

| Mode         | Description                    | Authorization Required |
|--------------|--------------------------------|------------------------|
| observation  | Read-only monitoring           | No                     |
| paper        | Simulated trading (testnet)    | No                     |
| live-advisory| Suggest trades, don't execute  | Yes                    |
| live-auto    | Full autonomous trading        | Yes + explicit confirm |

## Monitoring Protocol

When OWL monitors the bot, it checks:

1. **Bot process status** — Is it running? Any crash loops?
2. **Recent log output** — Any errors, rate limits, unusual patterns?
3. **Position summary** — Open positions, P&L, margin usage
4. **Order history** — Fills, rejections, slippage
5. **System health** — Latency, API connectivity, data freshness

## Risk Controls

**Hard Limits (cannot be overridden without user approval):**
- Maximum position size per trade: 10% of portfolio
- Maximum daily drawdown: 5%
- Maximum open positions: 5
- Stop-loss: mandatory on every position

**Soft Limits (OWL can adjust within bounds):**
- Take-profit targets
- Position sizing within the 10% cap
- Rebalancing frequency

## When to Alert the User

ALERT IMMEDIATELY for:
- Any live trade execution
- Drawdown exceeding 3%
- Bot crash or unexpected shutdown
- API connectivity loss > 2 minutes
- Any anomaly in order execution (slippage > expected, partial fills, etc.)

REPORT REGULARLY for:
- Daily P&L summary (on request)
- Position changes
- Signal-to-execution latency
- Market condition assessments

## Configuration Parameters

Key config knobs OWL can adjust:

```yaml
# Example trading config
strategy:
  type: "mean_reversion"  # or "momentum", "grid"
  timeframe: "5m"
  symbols: ["BTCUSDT", "ETHUSDT"]

risk:
  max_position_pct: 0.10
  max_daily_drawdown: 0.05
  stop_loss_pct: 0.02
  take_profit_pct: 0.04

execution:
  order_type: "limit"    # or "market"
  slippage_tolerance: 0.001
  retry_count: 3
```

## Safety Rules

1. **NEVER go live without explicit user confirmation.**
2. **Paper trade first.** Always validate a strategy in simulation before live deployment.
3. **Log every decision.** Every trade signal, execution, and override gets logged.
4. **Graceful degradation.** If market data is stale, pause trading — don't guess.
5. **Kill switch.** User can say "stop" at any time. OWL halts the bot immediately.
