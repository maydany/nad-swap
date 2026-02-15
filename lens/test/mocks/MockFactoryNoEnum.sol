// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract MockFactoryNoEnum {
    mapping(address => bool) public isPair;
    mapping(address => bool) public isQuoteToken;
    mapping(address => mapping(address => address)) public getPair;

    function setPair(address pair, bool enabled) external {
        isPair[pair] = enabled;
    }

    function setQuoteToken(address token, bool enabled) external {
        isQuoteToken[token] = enabled;
    }

    function setGetPair(address tokenA, address tokenB, address pair) external {
        getPair[tokenA][tokenB] = pair;
    }
}
