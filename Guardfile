# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'ctags-bundler', :src_path => %w(lib spec/support) do
  watch(/^(lib|spec\/support)\/.*\.rb$/)
  watch('Gemfile.lock')
end
