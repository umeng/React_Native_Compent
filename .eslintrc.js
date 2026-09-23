module.exports = {
  root: true,
  extends: ['@react-native'],
  rules: {
    'prettier/prettier': [
      'error',
      {
        singleQuote: true,
        trailingComma: 'all',
        tabWidth: 2,
        semi: true,
        bracketSpacing: true,
      },
    ],
  },
};
