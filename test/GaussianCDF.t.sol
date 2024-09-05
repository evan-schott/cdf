// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {GaussianCDF} from "../src/GaussianCDF.sol";
import "forge-std/StdJson.sol";

contract GaussianCDFTest is Test {
    GaussianCDF public gaussianCDF;
    int256 private constant WAD = 1e18;
    using stdJson for string;

    // Structs for deserializing the test cases from JSON.
    // The struct ordering is non-intuitive as it is forced to be alphabetical.
    struct TestCases {
        CDFTestCase[] fixed_dist;
        CDFTestCase[] full_range;
        CDFTestCase[] tight_range;
        CDFTestCase[] tight_range_scaled;
    }

    // Storing both representations is wasteful, but allows for more intuitive comparison.
    struct CDFTestCase {
        string cdf;
        string cdf_wad;
        string s;
        string s_wad;
        string u;
        string u_wad;
        string x;
        string x_wad;
    }

    function setUp() public {
        gaussianCDF = new GaussianCDF();
    }

    function test_fixed_dist() public view {
        TestCases memory testCases = load_test_cases();
        evaluate_test_case(testCases.fixed_dist);
    }

    function test_full_range() public view {
        TestCases memory testCases = load_test_cases();
        evaluate_test_case(testCases.full_range);
    }

    function test_tight_range() public view {
        TestCases memory testCases = load_test_cases();
        evaluate_test_case(testCases.tight_range);
    }

    function test_tight_range_scaled() public view {
        TestCases memory testCases = load_test_cases();
        evaluate_test_case(testCases.tight_range_scaled);
    }

    function evaluate_test_case(CDFTestCase[] memory testCase) public view {
        for (uint256 i = 0; i < testCase.length; i++) {
            int256 result = gaussianCDF.eval(
                toInt256(testCase[i].x_wad),
                toInt256(testCase[i].u_wad),
                toInt256(testCase[i].s_wad)
            );

            int256 expectation = toInt256(testCase[i].cdf_wad);
            assert(result <= expectation + 1e8);
            assert(result >= expectation - 1e8);
        }
    }

    function load_test_cases() public view returns (TestCases memory testCases) {
        string memory json = vm.readFile("./test/correctness/script/input/tests.json");
        bytes memory data = vm.parseJson(json);
        // Storing the test cases in storage is unimplemented feature in foundry at the moment.
        testCases = abi.decode(data, (TestCases));
    }

    function toInt256(string memory _a) internal pure returns (int256) {
        bytes memory b = bytes(_a);
        int256 result = 0;
        bool negative = false;
        uint256 i = 0;

        // Check for negative sign.
        if (b[0] == '-') {
            negative = true;
            i = 1;
        }

        // Iterate over the characters.
        for (; i < b.length; i++) {
            uint8 c = uint8(b[i]);
            result = result * 10 + (int8(c - 48));
        }

        if (negative) {
            result = -result;
        }

        return result;
    }

    function test_toInt256() public pure {
        assertEq(toInt256("0"), 0);
        assertEq(toInt256("1"), 1);
        assertEq(toInt256("10"), 10);
        assertEq(toInt256("123"), 123);
        assertEq(toInt256("-1"), -1);
        assertEq(toInt256("-10"), -10);
        assertEq(toInt256("-123"), -123);
        assertEq(toInt256("12345678901234567890123"), 12345678901234567890123);
        assertEq(toInt256("-901234567891234567880123"), -901234567891234567880123);
    }
}
