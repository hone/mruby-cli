def gem_config(conf)
  #conf.gembox 'default'

  # be sure to include this gem
  conf.gem File.expand_path(File.dirname(__FILE__))
end

MRuby::Build.new do |conf|
  toolchain :clang

  conf.enable_bintest

  gem_config(conf)
end

MRuby::CrossBuild.new('x86_64-apple-darwin14') do |conf|
  toolchain :clang

  [conf.cc, conf.linker].each do |cc|
    cc.command = 'x86_64-apple-darwin14-clang'
  end
  conf.cxx.command      = 'x86_64-apple-darwin14-clang++'
  conf.archiver.command = 'x86_64-apple-darwin14-ar'

  conf.build_target     = 'x86_64-pc-linux-gnu'
  conf.host_target      = 'x86_64-apple-darwin14'

  conf.build_mrbtest_lib_only

  gem_config(conf)
end

MRuby::CrossBuild.new('x86_64-w64-mingw32') do |conf|
  toolchain :gcc

  [conf.cc, conf.linker].each do |cc|
    cc.command = 'x86_64-w64-mingw32-gcc'
  end
  conf.cxx.command      = 'x86_64-w64-mingw32-cpp'
  conf.archiver.command = 'x86_64-w64-mingw32-gcc-ar'
  conf.exts.executable  = ".exe"

  conf.build_target     = 'x86_64-pc-linux-gnu'
  conf.host_target      = 'x86_64-w64-mingw32'

  conf.build_mrbtest_lib_only

  gem_config(conf)
end
