module.exports = {
  extends: ["lydell"],
  plugins: ["prettier"],
  parser: "babel-eslint",
  env: { es6: true },
  rules: {
    "prettier/prettier": "error",
  },
  globals: {
    Elm: false,
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
