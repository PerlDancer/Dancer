requires "Carp" => "0";
requires "Cwd" => "0";
requires "Data::Dumper" => "0";
requires "Encode" => "0";
requires "Exporter" => "0";
requires "Fcntl" => "0";
requires "File::Basename" => "0";
requires "File::Copy" => "0";
requires "File::Path" => "0";
requires "File::Spec" => "0";
requires "File::Spec::Functions" => "0";
requires "File::Temp" => "0";
requires "File::stat" => "0";
requires "FindBin" => "0";
requires "Getopt::Long" => "0";
requires "HTTP::Body" => "0";
requires "HTTP::Date" => "0";
requires "HTTP::Headers" => "0";
requires "HTTP::Server::Simple::PSGI" => "0";
requires "Hash::Merge::Simple" => "0";
requires "IO::File" => "0";
requires "LWP::UserAgent" => "0";
requires "MIME::Types" => "0";
requires "Module::Runtime" => "0";
requires "POSIX" => "0";
requires "Pod::Usage" => "0";
requires "Scalar::Util" => "0";
requires "Test::Builder" => "0";
requires "Test::More" => "0";
requires "Time::HiRes" => "0";
requires "Try::Tiny" => "0";
requires "URI" => "0";
requires "URI::Escape" => "0";
requires "base" => "0";
requires "bytes" => "0";
requires "constant" => "0";
requires "lib" => "0";
requires "overload" => "0";
requires "parent" => "0";
requires "strict" => "0";
requires "vars" => "0";
requires "warnings" => "0";
recommends "YAML" => "0";

on 'test' => sub {
  requires "Devel::Hide" => "0";
  requires "Digest::MD5" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "HTTP::Cookies" => "0";
  requires "HTTP::Request" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Plack::Builder" => "0";
  requires "Test::More" => "0";
  requires "Test::NoWarnings" => "0";
  requires "blib" => "1.01";
  requires "perl" => "5.006";
  requires "utf8" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Test::PAUSE::Permissions" => "0";
};
