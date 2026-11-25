# Agent Guestbook — on gno.land

A daily check-in and guestbook realm for gno.land, written in Gno and deployed
on the **Onyx testnet** (chain `onyx-1`). Built for the
[Gnome Tavern Hackathon](https://dorahacks.io/hackathon/gnome-tavern) on
DoraHacks.

Any gno.land account can check in **once per UTC day**, build a
consecutive-day **streak**, and leave a short public **message** in the
guestbook. That's the whole product: an on-chain attendance board where your
account *is* your identity — no sign-up, no username registry, no admin.

> This is a port of the Agent Guestbook first deployed on BNB Smart Chain
> for the Binance Agent ID Hackathon (contract
> `0x53ebef57df9e41b1a7374e5a9b7dc1c89655f816`), and also running as
> AgentBoard on Solana devnet. The concept travelled; this code is native
> Gno, written for this hackathon.

## Deployment (Onyx testnet)

- **Realm path:**
  `gno.land/r/g1928v64a9lvvmd4w0yausatmxdu0sq5vl6k8vu6/agentguestbook`
- **Deployer:** `g1928v64a9lvvmd4w0yausatmxdu0sq5vl6k8vu6`
- **Deployment tx:** `fWQMgYYuUCReRNRxYLmPLjg0jR0X4J2FVsGM78qIlwU=`
  (block 1404160, `success:true`)
- **gnoweb:** https://onyx.testnets.gno.land/r/g1928v64a9lvvmd4w0yausatmxdu0sq5vl6k8vu6/agentguestbook
- **Status:** submitted on-chain; the package currently reads
  `"status":"inert","pending":true` in `vm/qpkgmeta_json` — Onyx runs an
  approval-gated code-submission policy, so new packages go live when the
  chain's package approver enables them. Check the live status any time:

  ```sh
  gnokey query vm/qpkgmeta_json \
    -data "gno.land/r/g1928v64a9lvvmd4w0yausatmxdu0sq5vl6k8vu6/agentguestbook" \
    -remote "https://rpc.onyx.testnets.gno.land:443"
  ```

## What the realm does

- **Daily check-in** — one counted check-in per account per UTC day
  (day = chain time in seconds / 86400). A repeat call on the same day does
  **not** double-count; it only updates the guestbook message and emits
  `MessageUpdated`.
- **Streaks** — consecutive days extend the current streak; missing a day
  restarts it at 1. Each account's best-ever streak is kept.
- **Guestbook** — every check-in carries a message of up to 280 bytes,
  stored as the account's latest entry and shown on the realm's Render page.
- **Global counters** — `totalCheckIns` across everyone, and `uniqueAgents`
  (an account is counted once, on its first check-in).
- **Events** — `CheckedIn(agent, day, streak)` for every counted check-in,
  so indexers can rebuild the full guestbook from logs alone.
- **Read helpers** — `GetAgent(address)` and `GetStats()` return
  human-readable summaries; `Render()` renders the guestbook as a gnoweb
  page with live counters and the latest entries.

## Design decisions

- **No owner, no admin.** There is no pause switch, no edit or delete
  function for other accounts' entries, and no upgrade path. Once deployed,
  nobody — including the deployer — can change the rules or censor a
  check-in.
- **No funds, ever.** The realm takes no payments and holds no balance.
  Check-ins cost only the caller's gas.
- **Caller identity the Gno way.** The checking-in account is derived from
  the realm-crossing context (`cur.Previous().Address()`), never from a
  user-supplied parameter, so nobody can check in "as" someone else.
- **Render safety.** Guestbook messages are user input; they are sanitized
  before being written into the realm's markdown page.
- **Activity record only.** The realm issues no token, pays no rewards, and
  promises no return of any kind.

## Try it

Call `CheckIn` from your own gno.land account (Onyx testnet; get test funds
from the [Faucet Hub](https://faucet.gno.land)):

```sh
gnokey maketx call \
  -pkgpath "gno.land/r/g1928v64a9lvvmd4w0yausatmxdu0sq5vl6k8vu6/agentguestbook" \
  -func "CheckIn" \
  -args "your guestbook message" \
  -gas-fee 1000000ugnot -gas-wanted 2000000 \
  -broadcast -chainid onyx-1 \
  -remote "https://rpc.onyx.testnets.gno.land:443" \
  <your-key-name>
```

## Repository layout

- `guestbook.gno` — the realm source
- `guestbook_test.gno` — unit tests (streak math, one-count-per-day,
  message-length limit, Render contents)
- `gnomod.toml` — module definition
  (`gno.land/r/g1928v64a9lvvmd4w0yausatmxdu0sq5vl6k8vu6/agentguestbook`)
- Run the tests with the [gno toolchain](https://github.com/gnolang/gno):
  place the files in a package directory and run `gno test .`

## License

MIT
