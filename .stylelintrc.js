module.exports = {
  extends: [
    "stylelint-config-standard",
    "stylelint-config-property-sort-order-smacss",
  ],
  rules: {
    "font-family-name-quotes": "always-unless-keyword",
    "function-url-quotes": "always",
    "selector-attribute-quotes": "always",
    "string-quotes": "double",

    "at-rule-no-vendor-prefix": true,
    "media-feature-name-no-vendor-prefix": true,
    "property-no-vendor-prefix": true,
    "selector-no-vendor-prefix": true,
    "value-no-vendor-prefix": true,

    "max-line-length": [100, { ignorePattern: "/https?:\\/\\//" }],
  },
};
