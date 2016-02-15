def gem_config(conf)
  #conf.gembox 'default'

  # be sure to include this gem
  conf.gem File.expand_path(File.dirname(__FILE__))
end

MRuby::Build.new do |conf|
  toolchain :gcc

  conf.enable_bintest
  conf.enable_debug
  conf.enable_test

  gem_config(conf)
end

MRuby::Build.new('x86_64-pc-linux-gnu') do |conf|
  toolchain :gcc

  gem_config(conf)
end

MRuby::CrossBuild.new('i686-pc-linux-gnu') do |conf|
  toolchain :gcc

  [conf.cc, conf.cxx, conf.linker].each do |cc|
    cc.flags << "-m32"
  end

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

  gem_config(conf)
end

MRuby::CrossBuild.new('i386-apple-darwin14') do |conf|
  toolchain :clang

  [conf.cc, conf.linker].each do |cc|
    cc.command = 'i386-apple-darwin14-clang'
  end
  conf.cxx.command      = 'i386-apple-darwin14-clang++'
  conf.archiver.command = 'i386-apple-darwin14-ar'

  conf.build_target     = 'i386-pc-linux-gnu'
  conf.host_target      = 'i386-apple-darwin14'

  gem_config(conf)
end

MRuby::CrossBuild.new('x86_64-w64-mingw32') do |conf|
  toolchain :gcc

  [conf.cc, conf.linker].each do |cc|
    cc.command = 'x86_64-w64-mingw32-gcc'
  end
  conf.cxx.command      = 'x86_64-w64-mingw32-g++'
  conf.archiver.command = 'x86_64-w64-mingw32-gcc-ar'
  conf.exts.executable  = ".exe"

  conf.build_target     = 'x86_64-pc-linux-gnu'
  conf.host_target      = 'x86_64-w64-mingw32'

  gem_config(conf)
end

MRuby::CrossBuild.new('i686-w64-mingw32') do |conf|
  toolchain :gcc

  [conf.cc, conf.linker].each do |cc|
    cc.command = 'i686-w64-mingw32-gcc'
  end
  conf.cxx.command      = 'i686-w64-mingw32-g++'
  conf.archiver.command = 'i686-w64-mingw32-gcc-ar'
  conf.exts.executable  = ".exe"

  conf.build_target     = 'i686-pc-linux-gnu'
  conf.host_target      = 'i686-w64-mingw32'

  gem_config(conf)
end
