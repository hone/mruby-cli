MRuby::Gem::Specification.new('mruby-cli') do |spec|
  spec.license = 'MIT'
  spec.authors = ['Terence Lee', 'Zachary Scott']
  spec.summary = 'mruby cli utility'
  spec.bins    = ['mruby-cli']

  spec.add_dependency 'mruby-io',      :mgem => 'mruby-io'
  spec.add_dependency 'mruby-getopts', :mgem => 'mruby-getopts'
  spec.add_dependency 'mruby-dir',     :mgem => 'mruby-dir'
  spec.add_dependency 'mruby-docopt',  :github => 'hone/mruby-docopt'
end
