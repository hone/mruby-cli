MRuby::Gem::Specification.new('mruby-cli') do |spec|
  spec.license = 'MIT'
  spec.author  = 'Terence Lee'
  spec.summary = 'mruby cli utility'
  spec.bins    = ['mruby-cli']

  spec.add_dependency 'mruby-io', :github => 'hone/mruby-io'
  spec.add_dependency 'mruby-getopts', :github => 'hone/mruby-getopts'
  spec.add_dependency 'mruby-dir', :mgem => 'mruby-dir'
  spec.add_dependency 'mruby-mtest', :mgem => 'mruby-mtest'
end
