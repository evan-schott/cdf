// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {wadExp} from "@solmate-utils/SignedWadMath.sol";

/// @title A simulator for the cumulative distribution function of a Gaussian distribution.
/// @author Evan Schott
contract GaussianCDF {
    // Constants to avoid unnecessary calculationj.
    int128 private constant WAD_SQUARED = 1e36;
    int128 private constant WAD = 1e18;
    int128 private constant TWO_WAD = 2e18;
    int128 private constant MIN_ERF_INPUT = -5e19;
    int128 private constant MAX_ERF_INPUT = 5e19;
    int64 private constant SQRT_2 = 1414213562373095048;

    // Coefficients for the complementary error function.
    int64 private constant ERFC_0 = -1265512230000000000; // -1.26551223 * WAD;
    int64 private constant ERFC_1 =  1000023680000000000; //  1.00002368 * WAD;
    int64 private constant ERFC_2 =   374091960000000000; //  0.37409196 * WAD;
    int64 private constant ERFC_3 =    96784180000000000; //  0.09678418 * WAD;
    int64 private constant ERFC_4 =  -186288060000000000; // -0.18628806 * WAD;
    int64 private constant ERFC_5 =   278868070000000000; //  0.27886807 * WAD;
    int64 private constant ERFC_6 = -1135203980000000000; // -1.13520398 * WAD;
    int64 private constant ERFC_7 =  1488515870000000000; //  1.48851587 * WAD;
    int64 private constant ERFC_8 =  -822152230000000000; // -0.82215223 * WAD;
    int64 private constant ERFC_9 =   170872770000000000; //  0.17087277 * WAD;

    /// @notice Evaluates the cumulative distribution function for a given Gaussian distribution.
    /// @dev A broader survey of ERFC implementations could be surveyed to find a more efficient implementation. 
    /// @param x The value to evaluate the CDF at.
    /// @param u The mean of the Gaussian distribution.
    /// @param s The standard deviation of the Gaussian distribution.
    /// @return r The probability that a random variable from the Gaussian distribution is less than or equal to x.
    function eval(int256 x, int256 u, int256 s) public pure returns(int256) {
        unchecked {
            // Check that all inputs are within the desired bounds.
            if (x < -1e41 || x > 1e41) revert("INVALID_X");
            if (u < -1e38 || u > 1e38) revert("INVALID_MEAN");
            if (s <= 0 || s > 1e37) revert("INVALID_STDDEV");

            // Initialize variables used accross different assembly scopes.
            bool negative;
            int256 t; 
            int256 r;
            int256 z;
            int256 exponent;
            int256 p = ERFC_9;

            // Use assembly to remove unnecessary overflow checks.
            assembly {
                // Scale by mean and standard deviation.
                // Note that this cannot overflow since |x| is bounded by 1e41, and 1e59 ~ 2^196.
                z := sdiv(mul(sub(u, x), WAD), sdiv(mul(s, SQRT_2), WAD))
            }

            // If the input is too small, the result is 1.
            if (z < MIN_ERF_INPUT) {
                return WAD;
            }
            // If the input is too large, the result is 0.
            if (z > MAX_ERF_INPUT) {
                return 0;
            }

            assembly {
                // Keep the orginal signed value for later.
                negative := slt(z, 0)
                // Take the absolute value of the scaled input for usage in the error function.
                if negative {
                    z := sub(0, z)
                }

                // Calculate the complementary error function (Numerical Recipes in C 2e p221).
                t := div(WAD_SQUARED, add(WAD, shr(1, z)))

                // Horner's method for efficient polynomial evaluation of `p(t)`.
                p := add(sdiv(mul(p, t), WAD), ERFC_8)
                p := add(sdiv(mul(p, t), WAD), ERFC_7)
                p := add(sdiv(mul(p, t), WAD), ERFC_6)
                p := add(sdiv(mul(p, t), WAD), ERFC_5)
                p := add(sdiv(mul(p, t), WAD), ERFC_4)
                p := add(sdiv(mul(p, t), WAD), ERFC_3)
                p := add(sdiv(mul(p, t), WAD), ERFC_2)
                p := add(sdiv(mul(p, t), WAD), ERFC_1)
                p := add(sdiv(mul(p, t), WAD), ERFC_0) 

                // Calculate the exponent `p(t) - z^2`.
                exponent := sub(p, sdiv(mul(z, z), WAD)) 
            }
            
            // Use Solmate for efficient exponentiation.
            // Other alternatives where prb-math (too expensive), and ABDKMath (binary instead of decimal format).
            r = wadExp(exponent);

            assembly {
                // Final portion of erfc calculation.
                r := sdiv(mul(t, r), WAD)

                // Invert the probability if the original value was negative.
                if negative {
                    r := sub(TWO_WAD, r)
                }

                // Scale into desired probability range of [0, 1].
                r := shr(1, r)
            }

            return r;
        }
    }
}
