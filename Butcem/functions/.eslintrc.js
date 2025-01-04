module.exports = {
  root: true,
  env: {
    es6: true,
    node: true
  },
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended"
  ],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    sourceType: "module",
    tsconfigRootDir: __dirname
  },
  plugins: [
    "@typescript-eslint"
  ],
  rules: {
    "quotes": ["error", "double"],
    "semi": ["error", "always"],
    "@typescript-eslint/no-explicit-any": "warn",
    "max-len": ["error", { "code": 100 }]
  },
  ignorePatterns: [
    "/lib/**/*",
    "/node_modules/**"
  ]
};
