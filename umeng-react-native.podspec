require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = 'umeng-react-native'
  s.version      = package['version']
  s.summary      = package['description']
  s.homepage     = package['repository']['url']
  s.license      = package['license']
  s.authors      = 'Umeng+'
  s.source       = { :git => package['repository']['url'], :tag => s.version }

  s.platforms    = { :ios => '15.0' }
  s.source_files = 'ios/*.{h,m,mm}'

  # Use install_modules_dependencies helper to set up RN 0.73 dependencies
  if respond_to?(:install_modules_dependencies, true)
    install_modules_dependencies(s)
  else
    s.dependency 'React-Core'
  end

  # 友盟 Pod 依赖
  s.dependency 'UMCommon', '~> 7.0'
  s.dependency 'UMPush'
  s.dependency 'UMAPM'
  s.dependency 'UMShare/Core'
  s.dependency 'UMShare/UI'
end
