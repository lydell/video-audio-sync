const baseRules = require("eslint-config-lydell");

module.exports = {
  plugins: ["import", "prettier", "sort-imports-es6-autofix"],
  parser: "babel-eslint",
  env: { es6: true },
  rules: Object.assign({}, baseRules({ import: true }), {
    "prettier/prettier": "error",
    "sort-imports-es6-autofix/sort-imports-es6": "error",
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
