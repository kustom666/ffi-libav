require "bundler/gem_tasks"

rule ".rb" => ".xml" do |t|
  sh "bundle exec ffi-gen #{t.prerequisites.first} #{t.name}"
end

rule ".xml" => ".i" do |t|
  sh "swig -I/usr/include -xml -o #{t.source.sub(/\.i$/, ".xml")} #{t.source}"
end

task :default do
  system('rake -sT')
end

desc 'Run tests'
task(:test) do |t|
  unless File.exists? "spec/data/big_buck_bunny_480p_surround-fix.avi"
    puts <<EOM

=================================== NOTICE ====================================
Some of these tests require a video file to function.  For testing purposes we
use the freely available, creative commons movie Big Buck Bunny.  To get the
video file used for testing visit: http://bbb3d.renderfarming.net/download.html
Under the "Standard 2D" section, you can download the "480p HD (854x480)"
video; it should be named "big_buck_bunny_480p_surround-fix.avi" with SHA-256
40d1cf5bc8e1b0e55dac7bb2e3fbc2aea05b6679444864781299b24db044634f

Place this file, or a link to it at:
  spec/data/big_buck_bunny_480p_surround-fix.avi

Once that file is in place, you will no longer see this notice when starting
the tests.

                WITHOUT THIS VIDEO, SOME OF THE TESTS WILL FAIL.
===============================================================================

[ Press Enter to continue, ^C to abort ]
EOM
    STDIN.getc
  end
  sh "rspec"
end
