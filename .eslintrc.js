/* eslint-env node */

module.exports = {
  env: {
    es6: true
  },
  extends: ["eslint:recommended"],
  plugins: ["prettier"],
  rules: {
    "no-console": "off",
    "prettier/prettier": "error"
  },
  globals: {
    Elm: false,
    console: false,
    document: false,
    window: false
  }
};
