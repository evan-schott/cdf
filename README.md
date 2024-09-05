## Description
- Implementation of a an optimized gaussian CDF on the EVM for arbitrary 18 decimal fixed point parameters x, μ, σ. 
- Assume -1e20 ≤ μ ≤ 1e20 and 0 < σ ≤ 1e19. 
- Has an error less than 1e-8 vs `errcw/gaussian` for all x on the interval [-1e23, 1e23].

## Gas Data
- Tight range (scaled) across 1000 calls:
	- Min: 604
	- Avg: 1355 
	- Median: 1444 
	- Max: 1472
- Full range across 1000 calls:
	- Min: 604
	- Avg: 615 
	- Median: 604 
	- Max: 627
- Can generate new test cases with `test/correctness/script/test_generator.js`.

## Gas Analysis
- Gathered using `forge test --gas-report` and restricting based on testing function.
- When sampling from the full range, the data is boring, as everything is just fast exiting. 
- Using a tight range is more interesting, and a more reliable indicator of performance.

## Correctness
- Testing suite evaluates random inputs across 4 styles of distributions, and ensures that every output is within 1e-8 of the `errcw/gaussian` implementation. 

## Future work
- Survey alternative algorithms for approximating `erfc(x)`
- Goal was just to have `1e-8` error vs `errcw/gaussian`, there is also the tradeoff of actual error and gas usage.
- Could extend the contract to offer implementations of other gaussian functions.
- Only my second time writing a solidity contract, so would be cool to have more time to be able to dive into how Yul is compiled into EVM byte code to do more fine tuned optimization.
- Could try to write own WadExp function to remove overflow checks (since have tight range in `erfc`).
- All code has bugs: doing different styles of test cases to check for unexplored edge cases.

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```
