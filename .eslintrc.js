module.exports = {
    'env': {
        'commonjs': true,
        'es2021': true,
        'node': true,
        'browser': false,
    },
    'extends': [
        'plugin:json/recommended',
        'google',
    ],
    'plugins': [
        '@babel',
    ],
    // 'parser': '@babel/eslint-parser',
    'parserOptions': {
        'ecmaVersion': 12, // 12 or 2021 is the most current ECMAS Version
        'sourceType': 'module', // For use with JS Modules set to module, otherwise it can be set to script
        'allowImportExportEverywhere': false, // When set to true this configuration allows import and export declarations to be placed where ever a statement can be made. Obviously your Env must support the Dynamic placement of the import/export statements for it to work.
        'ecmaFeatures': {
            'globalReturn': false, // allow return statements in the global scope when used with sourceType: "script".
        },
    },
    'rules': {
        'new-cap': 'off',
        'max-len': 'off',
        'require-jsdoc': 'off',
        'arrow-body-style': 'off',
        'prefer-arrow-callback': 'off',
        'no-unused-expressions': 'off',
        // These are all the rules that Babel-Plugin has support for. If the plugin will implement a rule, you should have it do so instead of using ESLint's equal rule.
        '@babel/new-cap': 'off',
        '@babel/no-invalid-this': 'error',
        // '@babel/no-unused-expressions': 'error',
        '@babel/object-curly-spacing': 'error',
        '@babel/semi': 'off',
        /*
        I Omitted this rule because @Babel-Plugin offers this rule.
        "semi": ["error", "always"],    */

        'indent': ['error', 4, {'SwitchCase': 1}],
        'semi': ['error', 'never'],
        'camelcase': 'off',
        '@babel/no-unused-expressions': 'off',
        'no-unused-vars': 'warn',
    },
}
