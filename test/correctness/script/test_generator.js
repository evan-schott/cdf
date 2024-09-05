const fs = require('fs');
const gaussian = require('./lib/gaussian');

// Function to generate random integer between min and max (inclusive).
function getRandomInt(min, max) {
    return Math.random() * (max - min) + min;
}

// Function to convert a number to WAD.
function toWAD(x) {
    return BigInt(Math.round(x * 1e18));
}

// Create an instance of Gaussian.
const distribution = gaussian(0, 1);

// Function to generate test cases for a specific range.
function generateTestCases(rangeType, xRange, uRange, sRange) {
    const testCases = [];
    for (let i = 0; i < 1000; i++) {
        let x = getRandomInt(xRange[0], xRange[1]);
        let u = getRandomInt(uRange[0], uRange[1]);
        let s = getRandomInt(sRange[0], sRange[1]);

        distribution.mean = u;
        distribution.standardDeviation = s;
        
        // Evaluate the Gaussian CDF at the point x
        let cdf = distribution.cdf(x);
        
        // Convert the Bigint values to string representation.
        x_wad = (toWAD(x)).toLocaleString('fullwide', {useGrouping: false});
        x = x.toString()
        u_wad = (toWAD(u)).toLocaleString('fullwide', {useGrouping: false});
        u = u.toString();
        s_wad = (toWAD(s)).toLocaleString('fullwide', {useGrouping: false});
        s = s.toString();
        cdf_wad = (toWAD(cdf)).toLocaleString('fullwide', {useGrouping: false});
        cdf = cdf.toString();

        testCases.push({ cdf, cdf_wad, s, s_wad, u, u_wad, x, x_wad });
    }
    return testCases;
}

// Generate test cases for each category
const fixedDist = generateTestCases("fixed_dist", [-4, 4], [0, 0], [1, 1]);
const fullRange = generateTestCases("full_range", [-1e23, 1e23], [-1e20, 1e20], [1e-18, 1e18]);
const tightRange = generateTestCases("tight_range", [-40, 40], [-1, 1], [1e-18, 10]);
const tightRangeScaled = generateTestCases("tight_range_scaled", [-40e15, 40e15], [-1e15, 1e15], [1e-18, 1e16]);

// Combine all test cases
const testCases = {
    fixed_dist: fixedDist,
    full_range: fullRange,
    tight_range: tightRange,
    tight_range_scaled: tightRangeScaled,
};

// Write the test cases to a JSON file
fs.writeFile('input/tests.json', JSON.stringify(testCases, null, 2), (err) => {
    if (err) throw err;
    console.log('Test cases saved to tests.json');
});
