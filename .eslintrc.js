const baseRules = require("eslint-config-lydell");

module.exports = {
  plugins: ["prettier"],
  parser: "babel-eslint",
  env: { es6: true },
  rules: Object.assign({}, baseRules(), {
    "prettier/prettier": "error",
  }),
  globals: {
    DEBUG: false,
    console: false,
    document: false,
    window: false,
  },
  overrides: [
    {
      files: [".*.js", "*.config.js"],
      env: { node: true },
    },
  ],
};
