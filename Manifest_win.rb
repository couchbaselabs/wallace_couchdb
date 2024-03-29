# Do OS specific things here.
#
def product_platform()
  os_short + os_nbits
end

def win_make_flags()
  ""
end

def pthread_install
  "/usr"
end

def vbucketmigrator_configure_flags
end

def curl_test
  "#{base_tmp_install()}/bin/libcurl-4.dll"
end

def curl_configure_flags
  # Do not use --disable-shared for curl on windows,
  # because curl_easy_setopts() seems to go missing.
  ""
end

def licenses_file
  "licenses_win_20101221.tgz"
end

# ------------------------------------------------

# We don't have auto* tools on windows, so we need to copy
# pre-generated files (from some other system) instead.

def autorun_cmd(repo_name)
  ["cp -Rf #{STARTDIR}/components/autogen/#{repo_name}/* .",
   "touch Makefile"]
end

def autosave_cmd(repo_name, extras="")
  []
end

# ------------------------------------------------

load("./Manifest_win#{os_nbits}.rb")

COLLECT_PLATFORM_WIN =
  [
    { :desc => "erlang",
      :seq => 30,
      :src_dir => "/#{builder_erlang_dir()}",
      :dist => false,
      :force => true,
      :dst_dir => "components/Server",
      :except => [/.*\/doc/,
                  /.*\/src/,
                  /.*\/examples/,
                  /.*\/include/,
                  /.*\/Install/,
                  /.*\/Uninstall/,
                  /.*\/lib\/cos/,
                  /.*\/lib\/asn1-/,
                  /.*\/lib\/edoc-/,
                  /.*\/lib\/gs-/,
                  /.*\/lib\/ic-/,
                  /.*\/lib\/jinterface-/,
                  /.*\/lib\/megaco-/,
                  /.*\/lib\/orber-/,
                  /.*\/lib\/toolbar-/,
                  /.*\/lib\/wx-/,
                 ]
    },
    { :desc => "pre_geocouch",
      :seq  => 90,
      :step => Proc.new {|what|
        pull_make("#{BASEX}", "geocouch", VERSION_GEOCOUCH, "tar.gz",
                  { :os_arch => false,
                    :skip_file => true,
                    :no_parse_tag => true,
                    :branch => "origin/couchdb1.2.x",
                    :make => ["ls"]
                  }).call(what)
      }
    },
    { :desc => "couchdb",
      :seq => 100,
      :src_tgz => pull_make("#{BASEX}", "couchdb", VERSION_COUCHDB, "tar.gz",
                            { :os_arch => false,
                              :no_parse_tag => true,
                              :branch => "origin/couchbase-1.2.x",
                              :premake => autorun_cmd("couchdb") +
                                          ["sh ./configure --prefix=#{STARTDIR}/components/Server" +
                                                         " --with-js-include=#{STARTDIR}/#{BASE}/spidermonkey-3.7a3-winnt6.1/dist/include"+
                                                         " --with-js-lib=#{STARTDIR}/#{BASE}/spidermonkey-3.7a3-winnt6.1/dist/bin" +
                                                         " --with-win32-icu-binaries=#{STARTDIR}/#{BASE}/icu4c-4_2_1-Win32-msvc9/icu" +
                                                         " --with-erlang=#{builder_erlang_base()}/#{builder_erlang_dir()}/usr/include" +
                                                         " --with-win32-curl=#{STARTDIR}/#{BASE}/curl-7.20.1" +
                                                         " --with-msbuild-dir=#{DOTNET_FRAMEWORK_4}",
                                           "sleep 1", # Makefile might not be written yet.
                                           "sed -e \"s| INSTALL.gz| |\" <Makefile >Makefile.out",
                                           "sleep 1", # Makefile might not be written yet.
                                           "cp Makefile.out Makefile",
                                           "cp -f ../geocouch/share/www/script/test/*.* share/www/script/test/"],
                              :make => ["make -e LOCAL=#{base_tmp_install()}",
                                        "make install",
                                        "make --file=#{STARTDIR}/components/Makefile.couchdb_extra" +
                                                     " SRC_DIR=#{STARTDIR}/components/Server ERLANG_VER=#{ERLANG_VER} bdist"]
                            }),
      :dst_dir => "components/Server",
      :after   => mv_dir_proc()
    },
    { :desc => "geocouch",
      :seq  => 110,
      :step => Proc.new {|what|
        pull_make("#{BASEX}", "geocouch", VERSION_GEOCOUCH, "tar.gz",
                  { :os_arch => false,
                    :skip_file => true,
                    :no_parse_tag => true,
                    :branch => "origin/couchdb1.2.x",
                    :make => ["make -e COUCH_SRC=#{STARTDIR}/../couchdb/src/couchdb"]
                  }).call(what)
        FileUtils.mkdir_p("#{STARTDIR}/components/Server/lib/geocouch/ebin")
        FileUtils.cp_r(Dir.glob("#{STARTDIR}/../geocouch/build/*"),
                       "#{STARTDIR}/components/Server/lib/geocouch/ebin")
        FileUtils.mkdir_p("#{STARTDIR}/components/Server/etc/couchdb/local.d")
        FileUtils.cp_r(Dir.glob("#{STARTDIR}/../geocouch/etc/couchdb/local.d/*"),
                       "#{STARTDIR}/components/Server/etc/couchdb/local.d")
        FileUtils.mkdir_p("#{STARTDIR}/components/Server/share/couchdb/www/script/test")
        FileUtils.cp_r(Dir.glob("#{STARTDIR}/../geocouch/share/www/script/test/*"),
                       "#{STARTDIR}/components/Server/share/couchdb/www/script/test")
      }
    },
    { :desc => "openssl",
      :seq  => 200,
      :step => Proc.new {|what|
        FileUtils.cp("#{STARTDIR}/#{BASE}/openssl/libeay32.dll", "components/Server/bin/")
        FileUtils.cp("#{STARTDIR}/#{BASE}/openssl/libeay32.license.txt", "components/Server/bin/")
      }
    },
    { :desc => "cleanup",
      :seq  => 900,
      :step => Proc.new {|what|
        FileUtils.rm_rf("components/Server/PR.template")
      }
    },
    { :desc => "cleanup-staging",
      :seq  => -10,
      :step => Proc.new {|what|
        FileUtils.rm_rf("components/Server")
      }
    },
    { :desc => "set-erl-version",
      :seq  => -5,
      :step => Proc.new {|what|
        set_erl_version("components/platform_win/bin/service_register.bat")
        set_erl_version("components/platform_win/bin/service_reregister.bat")
        set_erl_version("components/platform_win/bin/service_start.bat")
        set_erl_version("components/platform_win/bin/service_stop.bat")
        set_erl_version("components/platform_win/bin/service_unregister.bat")
        set_erl_version("is_server/Script\ Files/Setup.Rul")
      }
    }
  ]

COLLECT_PLATFORM = COLLECT_PLATFORM_WIN.clone().concat(COLLECT_PLATFORM_WIN_BITSIZE_SPECIFIC)
