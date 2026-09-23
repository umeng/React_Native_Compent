module.exports = {
  dependency: {
    platforms: {
      android: {
        sourceDir: './android',
        packageImportPath: 'import com.umeng.rn.UMReactPackage;',
        packageInstance: 'new UMReactPackage()',
      },
      ios: {
        // Podspec auto-discovered from root
      },
    },
  },
};
