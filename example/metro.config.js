const path = require('path');
const { getDefaultConfig, mergeConfig } = require('@react-native/metro-config');
const exclusionList = require('metro-config/src/defaults/exclusionList');

const root = path.resolve(__dirname, '..');
const exampleNodeModules = path.resolve(__dirname, 'node_modules');

// Packages that must resolve to a single copy (from example/node_modules)
const singletonPkgs = ['react', 'react-native', 'react-native-screens', 'react-native-safe-area-context'];
const extraNodeModules = { 'umeng-react-native': root };
singletonPkgs.forEach(pkg => {
  extraNodeModules[pkg] = path.resolve(exampleNodeModules, pkg);
});

// Escape special regex characters in a path string
function escapeRegExp(s) { return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); }

// Block ALL copies of react/react-native EXCEPT example/node_modules/<pkg>
const blockPatterns = [
  // root/node_modules/react & react-native
  new RegExp(escapeRegExp(path.resolve(root, 'node_modules', 'react')) + '[\\/].*'),
  new RegExp(escapeRegExp(path.resolve(root, 'node_modules', 'react-native')) + '[\\/].*'),
  // Copied umeng-react-native/node_modules/react & react-native
  new RegExp(escapeRegExp(path.resolve(exampleNodeModules, 'umeng-react-native', 'node_modules', 'react')) + '[\\/].*'),
  new RegExp(escapeRegExp(path.resolve(exampleNodeModules, 'umeng-react-native', 'node_modules', 'react-native')) + '[\\/].*'),
];

/**
 * Metro configuration for the example app.
 * Resolves the library source from the parent directory.
 * Blocks duplicate react / react-native from root & copied node_modules.
 */
const config = {
  watchFolders: [root],
  resolver: {
    extraNodeModules,
    blockList: exclusionList(blockPatterns),
    nodeModulesPaths: [exampleNodeModules, path.resolve(root, 'node_modules')],
  },
};

module.exports = mergeConfig(getDefaultConfig(__dirname), config);
