#!/bin/bash

function build() {
    local which_ninja="$(command -v ninja 2>/dev/null)"
    if [ "$which_ninja" == "" ]; then
        which_ninja="$(command -v ninja-build 2>/dev/null)"
    fi

    local which_clang="$(command -v clang 2>/dev/null)"
    local which_clangpp="$(command -v clang++ 2>/dev/null)"
    local which_afl_gcc="$(command -v afl-gcc 2>/dev/null)"
    local which_afl_gpp="$(command -v afl-g++ 2>/dev/null)"
    local which_afl_clang="$(command -v afl-clang 2>/dev/null)"
    local which_afl_clangpp="$(command -v afl-clang++ 2>/dev/null)"
    local which_afl_fuzz="$(command -v afl-fuzz 2>/dev/null)"

    local do_env="false"
    local do_clean="false"
    local do_cached="true"
    local do_prep="false"
    local do_build="false"
    local do_test="false"
    local do_rpm="false"
    local do_deb="false"
    local do_sdeb="false"
    local do_popd="true"
    local do_fmt="false"
    local use_clang="false"
    local use_afl="false"
    local use_parallel_build="true"
    local use_parallel_tests="true"
    local config_args=()
    local cmake_args=()
    local make_args=()
    local ninja_args=()
    local ctest_args=("$BUILD_CTEST_ARGS" "--output-on-failure")
    local cflags="$CFLAGS"
    local cxxflags="$CXXFLAGS"
    local ccpath="$(command -v gcc 2>/dev/null)"
    local cxxpath="$(command -v g++ 2>/dev/null)"
    local py2path="$(command -v python2 2>/dev/null)"
    local py3path="$(command -v python3 2>/dev/null)"
    local pypath="$py3path"
    local starting_dir="$(pwd 2>/dev/null)"
    local git_root="$(git rev-parse --show-toplevel 2>/dev/null)"

    if (( ${#BUILD_CONFIGURE_ARGS[@]} > 0 )); then
        config_args=("${BUILD_CONFIGURE_ARGS[@]}")
    fi
    if (( ${#BUILD_CMAKE_ARGS[@]} > 0 )); then
        cmake_args=("${BUILD_CMAKE_ARGS[@]}")
    fi
    if (( ${#BUILD_MAKE_ARGS[@]} > 0 )); then
        make_args=("${BUILD_MAKE_ARGS[@]}")
    fi
    if (( ${#BUILD_NINJA_ARGS[@]} > 0 )); then
        ninja_args=("${BUILD_NINJA_ARGS[@]}")
    fi

    for arg in "$@"; do
        if [ "$arg" == "env" ]; then
            do_env="true"
        elif [ "$arg" == "clean" ]; then
            do_clean="true"
        elif [ "$arg" == "nocache" ] || [ "$arg" == "nocached" ]; then
            do_cached="false"
        elif [ "$arg" == "prep" ]; then
            do_prep="true"
        elif [ "$arg" == "build" ]; then
            do_build="true"
        elif [ "$arg" == "test" ] || [ "$arg" == "check" ]; then
            do_test="true"
        elif [ "$arg" == "all" ]; then
            do_env="true"
            do_clean="true"
            do_prep="true"
            do_build="true"
            do_test="true"
        elif [ "$arg" == "clang" ]; then
            use_clang="true"
        elif [ "$arg" == "debug" ]; then
            cmake_args+=("-DCMAKE_BUILD_TYPE=Debug")
            cflags="$cflags -Og -ggdb"
            cxxflags="$cxxflags -Og -ggdb"
        elif [ "$arg" == "optimized" ]; then
            cmake_args+=("-DCMAKE_BUILD_TYPE=Release")
            cflags="$cflags -O3 -march=native"
            cxxflags="$cxxflags -O3 -mtune=native"
        elif [ "$arg" == "warnings" ]; then
            cflags="$cflags -Wall -Wextra -Werror"
            cxxflags="$cxxflags -Wall -Wextra -Werror"
        elif [ "$arg" == "make" ]; then
            which_ninja=""
        elif [ "$arg" == "serial" ]; then
            use_parallel_build="false"
            use_parallel_tests="false"
        elif [ "$arg" == "serial-build" ]; then
            use_parallel_build="false"
        elif [ "$arg" == "serial-tests" ]; then
            use_parallel_tests="false"
        elif [ "$arg" == "python2" ]; then
            pypath="$py2path"
        elif [ "$arg" == "python3" ]; then
            pypath="$py3path"
        elif [ "$arg" == "nopop" ]; then
            do_popd="false"
        elif [ "$arg" == "fuzz" ]; then
            use_afl="true"
        elif [ "$arg" == "rpm" ]; then
            do_rpm="rpm"
        elif [ "$arg" == "srpm" ]; then
            do_rpm="srpm"
        elif [ "$arg" == "deb" ]; then
            do_deb="true"
        elif [ "$arg" == "sdeb" ]; then
            do_sdeb="true"
        elif [ "$arg" == "fmt" ]; then
            do_fmt="true"
        elif [ "$arg" == "asan" ]; then
            cflags="$cflags -fsanitize=address"
            cxxflags="$cxxflags -fsanitize=address"
        elif [ "$arg" == "lsan" ]; then
            cflags="$cflags -fsanitize=leak"
            cxxflags="$cxxflags -fsanitize=leak"
        elif [ "$arg" == "ubsan" ]; then
            cflags="$cflags -fsanitize=undefined -fsanitize=integer-divide-by-zero -fsanitize=unreachable -fsanitize=vla-bound -fsanitize=null -fsanitize=return -fsanitize=signed-integer-overflow -fsanitize=bounds -fsanitize=bounds-strict -fsanitize=alignment -fsanitize=object-size -fsanitize=float-divide-by-zero -fsanitize=float-cast-overflow -fsanitize=nonnull-attribute -fsanitize=returns-nonnull-attribute -fsanitize=bool -fsanitize=enum -fsanitize=vptr -fsanitize=pointer-overflow -fsanitize=builtin"
            cxxflags="$cflags -fsanitize=undefined -fsanitize=integer-divide-by-zero -fsanitize=unreachable -fsanitize=vla-bound -fsanitize=null -fsanitize=return -fsanitize=signed-integer-overflow -fsanitize=bounds -fsanitize=bounds-strict -fsanitize=alignment -fsanitize=object-size -fsanitize=float-divide-by-zero -fsanitize=float-cast-overflow -fsanitize=nonnull-attribute -fsanitize=returns-nonnull-attribute -fsanitize=bool -fsanitize=enum -fsanitize=vptr -fsanitize=pointer-overflow -fsanitize=builtin"
        elif [ "$arg" == "ssg-rhel" ]; then
            cmake_args+=("-DSSG_PRODUCT_DEFAULT=OFF" "-DSSG_PRODUCT_RHEL7=ON" "-DSSG_PRODUCT_RHEL8=ON")
        else
            echo "Ignoring unrecognized option: [$arg]"
        fi
    done

    if [ "$do_env" == "false" ] && [ "$do_clean" == "false" ] && [ "$do_prep" == "false" ] && [ "$do_build" == "false" ] && [ "$do_test" == "false" ] && [ "$do_rpm" == "false" ] && [ "$do_deb" == "false" ] && [ "$do_sdeb" == "false" ] && [ "$do_fmt" == "false" ]; then
        do_env="true"
        do_clean="true"
        do_prep="true"
        do_build="true"
    fi

    # Set ccpath/cxxpath based on arguments provided
    if [ "$use_afl" == "true" ] && [ "$which_afl_fuzz" != "" ] && [ "$use_clang" == "false" ]; then
        ccpath="$which_afl_gcc"
        cxxpath="$which_afl_gpp"
    elif [ "$use_afl" == "true" ] && [ "$which_afl_fuzz" != "" ] && [ "$use_clang" == "true" ]; then
        ccpath="$which_afl_clang"
        cxxpath="$which_afl_clangpp"
    elif [ "$use_clang" == "true" ]; then
        if [ "$which_clang" != "" ] && [ "$which_clangpp" != "" ]; then
            ccpath="$which_clang"
            cxxpath="$which_clangpp"
        fi
        cflags="-Wno-unused-command-line-argument $cflags -Wno-unused-command-line-argument"
        cxxflags="-Wno-unused-command-line-argument $cxxflags -Wno-unused-command-line-argument"
    fi

    if [ "$use_parallel_build" == "true" ]; then
        local num_cores="$(nproc)"
        num_cores=$(( num_cores + 2 ))
        make_args+=("-j" "$num_cores")
        ninja_args+=("-j" "$num_cores")
    else
        make_args+=("-j" "1")
        ninja_args+=("-j" "1")
    fi

    if [ "$use_parallel_tests" == "true" ]; then
        local num_cores="$(grep -c '^processor[[:space:]]*:' < /proc/cpuinfo)"
        ctest_args+=("-j" "$(( num_cores / 2 ))")
    else
        ctest_args+=("-j" "1")
    fi

    cmake_args+=("-DCMAKE_C_COMPILER=$ccpath"
        "-DCMAKE_CXX_COMPILER=$cxxpath"
        "-DPYTHON_EXECUTABLE=$pypath"
    )

    if [ "$do_cached" == "true" ]; then
        cmake_args+=("-DSSG_JINJA2_CACHE_DIR=~/.ssg_jinja_cache")
    else
        export CCACHE_DISABLE=1
    fi

    if [ "$do_test" == "true" ]; then
        cmake_args+=("-DENABLE_TESTING=ON")
    fi

    function __build_cd() {
        if [ "$git_root" == "" ]; then
            return
        fi

        if [ "$starting_dir" != "$git_root" ]; then
            cd "$git_root" || return
        fi
    }

    function __build_info() {
        echo "start dir: $starting_dir" 1>&2
        echo "git root: $git_root" 1>&2
        echo "cc path: $ccpath" 1>&2
        echo "cflags: $cflags" 1>&2
        echo "cxx path: $cxxpath" 1>&2
        echo "cxxflags: $cxxflags" 1>&2
        echo "python path: $pypath" 1>&2
        echo "config args:" "${config_args[@]}"
        echo "cmake args:" "${cmake_args[@]}"
        echo "make args:" "${make_args[@]}"
        echo "ninja args:" "${ninja_args[@]}"
        echo "ctest args:" "${ctest_args[@]}"
        echo "do_env: $do_env" 1>&2
        echo "do_clean: $do_clean" 1>&2
        echo "do_prep: $do_prep" 1>&2
        echo "do_build: $do_build" 1>&2
        echo "do_test: $do_test" 1>&2
        echo "do_rpm: $do_rpm" 1>&2
        echo "do_deb: $do_deb" 1>&2
        echo "do_sdeb: $do_sdeb" 1>&2
        echo "do_fmt: $do_fmt" 1>&2
    }

    function __build_env_jss() {
        if [ "$JAVA_HOME" == "" ] && [ -e tools/autoenv.sh ]; then
            source tools/autoenv.sh
        fi
    }

    function __build_env() {
        if [ -e "tools/autoenv.sh" ]; then
            __build_env_jss
        fi
    }

    function __build_clean_cmake() {
        local have_build_gitkeep=false
        if [ -e "build/.gitkeep" ]; then
            have_build_gitkeep=true
        fi

        (rm -rf build && mkdir -p build) || return 1
        if [ $have_build_gitkeep ]; then
            touch build/.gitkeep
        fi
    }

    function __build_clean_make() {
        # Some Makefiles will fail on a cleaned repo
        make clean distclean
        return 0
    }

    function __build_clean_python() {
        $pypath setup.py clean || return $?
        if [ -d "build" ]; then
            rm -rf build
        fi
        return 0
    }

    function __build_clean_maven() {
        mvn clean
    }

    function __build_clean_gradle() {
        if [ -e "gradlew" ]; then
            bash ./gradlew clean
        else
            gradle clean
        fi
    }

    function __build_clean_nss() {
        rm -rf out ../dist ../nspr/{Debug,Release}
    }

    function __build_clean_cargo() {
        cargo clean
    }

    function __build_clean() {
        if [ -e "CMakeLists.txt" ] || [ -e meson.build ]; then
            # CMake must be higher priority than Makefile in case the project
            # was built in-tree or includes other targets.
            __build_clean_cmake
        elif [ -e "nss.gyp" ]; then
            # NSS must be higher priority than Makefile because we use gyp and
            # its build.sh script instead.
            __build_clean_nss
        elif [ -e "Makefile" ] || [ -e "GNUmakefile" ]; then
            __build_clean_make
        elif [ -e "setup.py" ]; then
            __build_clean_python
        elif [ -e "pom.xml" ]; then
            __build_clean_maven
        elif [ -e "Cargo.toml" ]; then
            __build_clean_cargo
        elif [ -e "gradle.properties" ]; then
            __build_clean_gradle
		elif [ -e "clean.bash" ]; then
			if [ -e "../bin" ] && [ ! -e "../bin/go" ]; then
				echo "Nothing to clean in Go build system"
				return 0
			fi
			bash clean.bash
        elif [ -e "src" ]; then
            pushd src || return 1
            __build_clean
            local ret=$?
            popd || return 1
            return $ret
        fi
        return 0
    }

    function __build_prep_cmake_ninja() {
        CFLAGS="$cflags" CXXFLAGS="$cxxflags" time -p cmake "${cmake_args[@]}" -G Ninja ..
    }

    function __build_prep_cmake_make() {
        CFLAGS="$cflags" CXXFLAGS="$cxxflags" time -p cmake "${cmake_args[@]}" -G "Unix Makefiles" ..
    }

    function __build_prep_cmake() {
        if [ -d "build" ]; then
            cd build || return 1
        fi

        if [ "$which_ninja" == "" ]; then
            echo "Prepping with cmake/make"
            __build_prep_cmake_make
        else
            echo "Prepping with cmake/ninja"
            __build_prep_cmake_ninja
        fi
    }

    function __build_prep_meson() {
        meson setup build
    }

    function __build_prep_autotools() {
        if [ ! -e "configure" ] && [ ! -e "config" ] && [ ! -e "Configure" ]; then
            if [ -e autogen.sh ]; then
                time -p ./autogen.sh
            else
                time -p autoreconf -f -i
            fi
        fi
        local path="./configure"
        if [ -e "./config" ] && [ ! -d "./config" ]; then
            path="./config"
        elif [ -e "./Configure" ]; then
            path="./Configure"
        fi
        CC="$ccpath" CXX="$cxxpath" CFLAGS="$cflags" CXXFLAGS="$cxxflags" time -p "$path" "${config_args[@]}"
    }

    function __build_prep_python_setuptools() {
        $pypath -m pip install --user -r test-requirements.txt
        CC="$ccpath" CXX="$cxxpath" CFLAGS="$cflags" CXXFLAGS="$cxxflags" $pypath setup.py check
    }

    function __build_prep_make_bootstrap() {
        make -q bootstrap
        if (( $? == 0 )); then
            time -p make bootstrap
        fi
    }

    function __build_prep_gradle() {
        if [ ! -e gradle/wrapper/gradle-wrapper.jar ]; then
            time -p gradle wrapper
        fi
    }

    function __build_prep() {
        if [ -e "CMakeLists.txt" ]; then
            __build_prep_cmake
        elif [ -e "meson.build" ]; then
            __build_prep_meson
        elif [ -e "configure.ac" ] || [ -e "configure.in" ] || [ -e "configure" ] || [ -e "config" -a ! -d "config" ] || [ -e "Configure" ]; then
            __build_prep_autotools
        elif [ -e "setup.py" ]; then
            __build_prep_python_setuptools
        elif [ -e "gradle.properties" ]; then
            __build_prep_gradle
        elif [ -e "pom.xml" ] || [ -e "Cargo.toml" ]; then
            # Nothing to do for maven or cargo builds.
            return 0
        elif [ -e "Makefile" ] || [ -e "GNUmakefile" ]; then
            # If there is already a Makefile, try running it :)
            __build_prep_make_bootstrap
		elif [ -e "run.bash" ] && [ -e "make.bash" ] && [ -e "clean.bash" ]; then
			return 0
        elif [ -d "src" ]; then
            pushd src || return 1
            __build_prep
            local ret=$?
            popd || return 1
            return $ret
        else
            echo "Cannot build prep: unknown build system"
            return 1
        fi
    }

    function __build_make() {
        time -p make "${make_args[@]}"
    }

    function __build_ninja() {
        time -p $which_ninja "${ninja_args[@]}"
    }

    function __build_python() {
        CC="$ccpath" CXX="$cxxpath" CFLAGS="$cflags" CXXFLAGS="$cxxflags" time -p $pypath setup.py build
    }

    function __build_maven() {
        time -p mvn compile
    }

    function __build_nss() {
        time -p bash build.sh --enable-fips --enable-libpkix
    }

    function __build_cargo() {
        time -p cargo build
    }

    function __build_gradle() {
        if [ -e "gradlew" ]; then
            time -p bash ./gradlew build compileTestJava -x test -x check
        else
            time -p gradle build compileTestJava -x test -x check
        fi
    }

    function __build() {
        if [ "$which_ninja" != "" ] && [ -e "build.ninja" ]; then
            echo "Building with ninja"
            __build_ninja
        elif [ -e "nss.gyp" ]; then
            # NSS must be higher priority than Makefile because we use gyp and
            # its build.sh script instead.
            __build_nss
        elif [ -e "Makefile" ] || [ -e "GNUmakefile" ]; then
            echo "Building with make"
            __build_make
        elif [ -e "setup.py" ]; then
            echo "Building with setup.py"
            __build_python
        elif [ -e "pom.xml" ]; then
            __build_maven
		elif [ -e "make.bash" ]; then
			bash make.bash
        elif [ -e "Cargo.toml" ]; then
            __build_cargo
        elif [ -e "gradle.properties" ]; then
            __build_gradle
        elif [ -d "build" ]; then
            pushd build || return 1
            __build
            local ret=$?
            popd || return 1
            return $ret
        elif [ -d "src" ]; then
            pushd src || return 1
            __build
            local ret=$?
            popd || return 1
            return $ret
        else
            echo "Unknown build system!"
            return 1
        fi
    }

    function __build_test_ctest() {
        time -p ctest "${ctest_args[@]}"
    }

    function __build_test_make() {
        make -q check
        check_ret=$?

        make -q test
        test_ret=$?

        if [[ $check_ret == 1 ]]; then
            time -p make check
        elif [[ $test_ret == 1 ]]; then
            time -p make test
        else
            echo "Unknown make system! Targets 'test' and 'check' missing."
            return 1
        fi
    }

    function __build_test_python() {
        if [ -d tests ]; then
            if [ "$pypath" == "$py2path" ]; then
                time -p pytest
            else
                time -p pytest-3
            fi
        fi
        time -p $pypath setup.py test
    }

    function __build_test_maven() {
        time -p mvn test
    }

    function __build_test_nss() {
        export HOST="localhost"
        export DOMSUF="localdomain"
        export USE_64=1
        pushd tests || return 1
        time -p bash all.sh
        local ret=$?
        popd || return 1
        return $ret
    }

    function __build_test_cargo() {
        time -p cargo test
    }

    function __build_test_gradle() {
        if [ -e "gradlew" ]; then
            time -p bash ./gradlew test check
        else
            time -p gradle test check
        fi
    }

    function __build_test() {
        if [ -e "CMakeCache.txt" ]; then
            __build_test_ctest
        elif [ -e "nss.gyp" ]; then
            # NSS must be higher priority than Makefile because we use gyp and
            # its build.sh script instead.
            __build_test_nss
        elif [ -e "Makefile" ] || [ -e "GNUmakefile" ]; then
            __build_test_make
        elif [ -e "setup.py" ]; then
            __build_test_python
        elif [ -e "Cargo.toml" ]; then
            __build_test_cargo
        elif [ -d "build" ]; then
            pushd build || return 1
            __build_test
            local ret=$?
            popd || return 1
            return $ret
        elif [ -d "pom.xml" ]; then
            __build_test_maven
		elif [ -e "run.bash" ]; then
			bash run.bash
        elif [ -e "gradle.properties" ]; then
            __build_test_gradle
        elif [ -d "src" ]; then
            pushd src || return 1
            __build_test
            local ret=$?
            popd || return 1
            return $ret
        else
            echo "Unknown test system!"
            return 1
        fi
    }

    function __build_rpm_script() {
        time -p bash build.sh --with-timestamp --with-commit-id "$do_rpm"
    }

    function __build_rpm() {
        if [ -e "build.sh" ]; then
            __build_rpm_script
        else
            echo "Unknown rpm system!"
            return 1
        fi
    }

    function __build_deb() {
        if [ -e "debian/control" ]; then
            dpkg-buildpackage -us -uc
        else
            echo "Unknown deb system!"
            return 1
        fi
    }

    function __build_sdeb() {
        if [ -e "debian/control" ]; then
            debuild -S -k"${DEBIAN_KEY_ID:-Scheel}"
        else
            echo "Unknown deb system!"
            return 1
        fi
    }

    function __build_fmt_cargo() {
        cargo fmt
    }

    function __build_fmt_make() {
        make -q fmt
        fmt_ret=$?

        make -q format
        format_ret=$?

        if [[ $fmt_ret == 1 ]]; then
            make fmt
        elif [[ $format_ret == 1 ]]; then
            make format
        else
            echo "Unknown make system! Targets 'fmt' and 'format' missing."
            return 1
        fi
    }


    function __build_fmt() {
        if [ -e "Cargo.toml" ]; then
            __build_fmt_cargo
        elif [ -e "Makefile" ] || [ -e "GNUmakefile" ]; then
            __build_fmt_make
        else
            echo "Unable to format project!"
            return 1
        fi
    }

    function __build_uncd() {
        local cpwd="$(pwd 2>/dev/null)"

        if [ "$cpwd" != "" ] && [ "$cpwd" != "$starting_dir" ]; then
            cd "$starting_dir" || return
        fi
    }

    __build_cd
    __build_info

    if [ "$do_env" == "true" ]; then
        __build_env
        ret="$?"
        if (( ret != 0 )); then
            echo "Environment failed with status: $ret"
            return $ret
        fi
    fi

    if [ "$do_clean" == "true" ]; then
        __build_clean
        ret="$?"
        if (( ret != 0 )); then
            echo "Clean failed with status: $ret"
            return $ret
        fi
    fi

    if [ "$do_prep" == "true" ]; then
        __build_prep
        ret="$?"
        if (( ret != 0 )); then
            echo "Prep failed with status: $ret"
            return $ret
        fi
    fi

    if [ "$do_build" == "true" ]; then
        __build
        ret="$?"
        if (( ret != 0 )); then
            echo "Build failed with status: $ret"
            return $ret
        fi
    fi

    if [ "$do_test" == "true" ]; then
        __build_test
        ret="$?"
        if (( ret != 0 )); then
            echo "Test failed with status: $ret"
            return $ret
        fi
    fi

    if [ "$do_rpm" != "false" ]; then
        __build_rpm
        ret="$?"
        if (( ret != 0 )); then
            echo "RPM failed with status: $ret"
            return $ret
        fi
    fi

    if [ "$do_deb" == "true" ]; then
        __build_deb
        ret="$?"
        if (( ret != 0 )); then
            echo "DEB failed with status: $ret"
            return $ret
        fi
    fi

    if [ "$do_sdeb" == "true" ]; then
        __build_sdeb
        ret="$?"
        if (( ret != 0 )); then
            echo "Source DEB failed with status: $ret"
            return $ret
        fi
    fi

    if [ "$do_fmt" == "true" ]; then
        __build_fmt
        ret="$?"
        if (( ret != 0 )); then
            echo "Format failed with status: $ret"
            return $ret
        fi
    fi

    if [ "$do_popd" == "true" ]; then
        __build_uncd
    fi
    return 0
}
