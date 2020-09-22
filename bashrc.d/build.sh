#!/bin/bash

function build() {
    local which_ninja="$(command -v ninja 2>/dev/null)"
    if [ "x$which_ninja" == "x" ]; then
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
    local do_prep="false"
    local do_build="false"
    local do_test="false"
    local do_rpm="false"
    local do_popd="true"
    local use_clang="false"
    local use_afl="false"
    local use_parallel_build="true"
    local use_parallel_tests="true"
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
        if [ "x$arg" == "xenv" ]; then
            do_env="true"
        elif [ "x$arg" == "xclean" ]; then
            do_clean="true"
        elif [ "x$arg" == "xprep" ]; then
            do_prep="true"
        elif [ "x$arg" == "xbuild" ]; then
            do_build="true"
        elif [ "x$arg" == "xtest" ]; then
            do_test="true"
        elif [ "x$arg" == "xall" ]; then
            do_env="true"
            do_clean="true"
            do_prep="true"
            do_build="true"
            do_test="true"
        elif [ "x$arg" == "xclang" ]; then
            use_clang="true"
        elif [ "x$arg" == "xdebug" ]; then
            cmake_args+=("-DCMAKE_BUILD_TYPE=Debug")
            cflags="$cflags -Og -ggdb"
            cxxflags="$cxxflags -Og -ggdb"
        elif [ "x$arg" == "xoptimized" ]; then
            cmake_args+=("-DCMAKE_BUILD_TYPE=Release")
            cflags="$cflags -O3 -march=native"
            cxxflags="$cxxflags -O3 -mtune=native"
        elif [ "x$arg" == "xwarnings" ]; then
            cflags="$cflags -Wall -Wextra -Werror"
            cxxflags="$cxxflags -Wall -Wextra -Werror"
        elif [ "x$arg" == "xmake" ]; then
            which_ninja=""
        elif [ "x$arg" == "xserial" ]; then
            use_parallel_build="false"
            use_parallel_tests="false"
        elif [ "x$arg" == "xserial-build" ]; then
            use_parallel_build="false"
        elif [ "x$arg" == "xserial-tests" ]; then
            use_parallel_tests="false"
        elif [ "x$arg" == "xpython2" ]; then
            pypath="$py2path"
        elif [ "x$arg" == "xpython3" ]; then
            pypath="$py3path"
        elif [ "x$arg" == "xnopop" ]; then
            do_popd="false"
        elif [ "x$arg" == "xfuzz" ]; then
            use_afl="true"
        elif [ "x$arg" == "xrpm" ]; then
            do_rpm="rpm"
        elif [ "x$arg" == "xsrpm" ]; then
            do_rpm="srpm"
        elif [ "x$arg" == "xasan" ]; then
            cflags="$cflags -fsanitize=address"
            cxxflags="$cxxflags -fsanitize=address"
        elif [ "x$arg" == "xlsan" ]; then
            cflags="$cflags -fsanitize=leak"
            cxxflags="$cxxflags -fsanitize=leak"
        elif [ "x$arg" == "xubsan" ]; then
            cflags="$cflags -fsanitize=undefined -fsanitize=integer-divide-by-zero -fsanitize=unreachable -fsanitize=vla-bound -fsanitize=null -fsanitize=return -fsanitize=signed-integer-overflow -fsanitize=bounds -fsanitize=bounds-strict -fsanitize=alignment -fsanitize=object-size -fsanitize=float-divide-by-zero -fsanitize=float-cast-overflow -fsanitize=nonnull-attribute -fsanitize=returns-nonnull-attribute -fsanitize=bool -fsanitize=enum -fsanitize=vptr -fsanitize=pointer-overflow -fsanitize=builtin"
            cxxflags="$cflags -fsanitize=undefined -fsanitize=integer-divide-by-zero -fsanitize=unreachable -fsanitize=vla-bound -fsanitize=null -fsanitize=return -fsanitize=signed-integer-overflow -fsanitize=bounds -fsanitize=bounds-strict -fsanitize=alignment -fsanitize=object-size -fsanitize=float-divide-by-zero -fsanitize=float-cast-overflow -fsanitize=nonnull-attribute -fsanitize=returns-nonnull-attribute -fsanitize=bool -fsanitize=enum -fsanitize=vptr -fsanitize=pointer-overflow -fsanitize=builtin"
        elif [ "x$arg" == "xssg-rhel" ]; then
            cmake_args+=("-DSSG_PRODUCT_DEFAULT=OFF" "-DSSG_PRODUCT_RHEL7=ON" "-DSSG_PRODUCT_RHEL8=ON")
        fi
    done

    if [ "$do_env" == "false" ] && [ "$do_clean" == "false" ] && [ "$do_prep" == "false" ] && [ "$do_build" == "false" ] && [ "$do_test" == "false" ] && [ "$do_rpm" == "false" ]; then
        do_env="true"
        do_clean="true"
        do_prep="true"
        do_build="true"
    fi

    # Set ccpath/cxxpath based on arguments provided
    if [ "$use_afl" == "true" ] && [ "x$which_afl_fuzz" != "x" ] && [ "$use_clang" == "false" ]; then
        ccpath="$which_afl_gcc"
        cxxpath="$which_afl_gpp"
    elif [ "$use_afl" == "true" ] && [ "x$which_afl_fuzz" != "x" ] && [ "$use_clang" == "true" ]; then
        ccpath="$which_afl_clang"
        cxxpath="$which_afl_clangpp"
    elif [ "$use_clang" == "true" ]; then
        if [ "x$which_clang" != "x" ] && [ "x$which_clangpp" != "x" ]; then
            ccpath="$which_clang"
            cxxpath="$which_clangpp"
        fi
        cflags="-Wno-unused-command-line-argument $cflags -Wno-unused-command-line-argument"
        cxxflags="-Wno-unused-command-line-argument $cxxflags -Wno-unused-command-line-argument"
    fi

    if [ "$use_parallel_build" == "true" ]; then
        local num_cores="$(grep -c '^processor[[:space:]]*:' < /proc/cpuinfo)"
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
        "-DSSG_JINJA2_CACHE_DIR=~/.ssg_jinja_cache"
    )

    if [ "$do_test" == "true" ]; then
        cmake_args+=("-DENABLE_TESTING=ON")
    fi

    function __build_cd() {
        if [ "x$git_root" == "x" ]; then
            return
        fi

        if [ "x$starting_dir" != "x$git_root" ]; then
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
    }

    function __build_env_jss() {
        if [ "x$JAVA_HOME" == "x" ] && [ -e tools/autoenv.sh ]; then
            source tools/autoenv.sh
            return $?
        fi
    }

    function __build_env() {
        if [ -e "tools/autoenv.sh" ]; then
            __build_env_jss
            return $?
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

    function __build_clean_nss() {
        rm -rf out ../dist ../nspr/{Debug,Release}
    }

    function __build_clean() {
        if [ -e "CMakeLists.txt" ] || [ -e meson.build ]; then
            # CMake must be higher priority than Makefile in case the project
            # was built in-tree or includes other targets.
            __build_clean_cmake
            return $?
        elif [ -e "nss.gyp" ]; then
            # NSS must be higher priority than Makefile because we use gyp and
            # its build.sh script instead.
            __build_clean_nss
            return $?
        elif [ -e "Makefile" ]; then
            __build_clean_make
            return $?
        elif [ -e "setup.py" ]; then
            __build_clean_python
            return $?
        elif [ -e "pom.xml" ]; then
            __build_clean_maven
            return $?
        elif [ -e "src" ]; then
            pushd src || return 1
            __build_clean
            local ret=$?
            popd
            return $ret
        fi
        return 0
    }

    function __build_prep_cmake_ninja() {
        CFLAGS="$cflags" CXXFLAGS="$cxxflags" time -p cmake "${cmake_args[@]}" -G Ninja ..
        return $?
    }

    function __build_prep_cmake_make() {
        CFLAGS="$cflags" CXXFLAGS="$cxxflags" time -p cmake "${cmake_args[@]}" -G "Unix Makefiles" ..
        return $?
    }

    function __build_prep_cmake() {
        if [ -d "build" ]; then
            cd build || return 1
        fi

        if [ "x$which_ninja" == "x" ]; then
            echo "Prepping with cmake/make"
            __build_prep_cmake_make
            return $?
        else
            echo "Prepping with cmake/ninja"
            __build_prep_cmake_ninja
            return $?
        fi
    }

    function __build_prep_meson() {
        meson setup build
    }

    function __build_prep_autotools() {
        if [ ! -e "configure" ]; then
            if [ -e autogen.sh ]; then
                time -p ./autogen.sh
            else
                time -p autoreconf -f -i
            fi
        fi
        CC="$ccpath" CXX="$cxxpath" CFLAGS="$cflags" CXXFLAGS="$cxxflags" time -p ./configure
        return $?
    }

    function __build_prep_python_setuptools() {
        $pypath -m pip install --user -r test-requirements.txt
        CC="$ccpath" CXX="$cxxpath" CFLAGS="$cflags" CXXFLAGS="$cxxflags" $pypath setup.py check
        return $?
    }

    function __build_prep() {
        if [ -e "CMakeLists.txt" ]; then
            __build_prep_cmake
            return $?
        elif [ -e "meson.build" ]; then
            __build_prep_meson
        elif [ -e "configure.ac" ] || [ -e "configure.in" ]; then
            __build_prep_autotools
            return $?
        elif [ -e "setup.py" ]; then
            __build_prep_python_setuptools
            return $?
        elif [ -e "pom.xml" ]; then
            # Nothing to do for maven builds.
            return 0
        elif [ -e "Makefile" ]; then
            # If there is already a Makefile, try running it :)
            return 0
        elif [ -d "src" ]; then
            pushd src || return
            __build_prep
            local ret=$?
            popd
            return $ret
        else
            echo "Cannot build prep: unknown build system"
            return 1
        fi
    }

    function __build_make() {
        time -p make "${make_args[@]}"
        return $?
    }

    function __build_ninja() {
        time -p $which_ninja "${ninja_args[@]}"
        return $?
    }

    function __build_python() {
        CC="$ccpath" CXX="$cxxpath" CFLAGS="$cflags" CXXFLAGS="$cxxflags" time -p $pypath setup.py build
        return $?
    }

    function __build_maven() {
        time -p maven compile
        return $?
    }

    function __build_nss() {
        time -p bash build.sh --enable-fips --enable-libpkix
        return $?
    }

    function __build() {
        if [ "x$which_ninja" != "x" ] && [ -e "build.ninja" ]; then
            echo "Building with ninja"
            __build_ninja
            return $?
        elif [ -e "nss.gyp" ]; then
            # NSS must be higher priority than Makefile because we use gyp and
            # its build.sh script instead.
            __build_nss
            return $?
        elif [ -e "Makefile" ]; then
            echo "Building with make"
            __build_make
            return $?
        elif [ -e "setup.py" ]; then
            echo "Building with setup.py"
            __build_python
            return $?
        elif [ -e "pom.xml" ]; then
            __build_maven
            return $?
        elif [ -d "build" ]; then
            pushd build || return 1
            __build
            local ret=$?
            popd
            return $ret
        elif [ -d "src" ]; then
            pushd src || return 1
            __build
            local ret=$?
            popd
            return $ret
        else
            echo "Unknown build system!"
            return 1
        fi
    }

    function __build_test_ctest() {
        time -p ctest "${ctest_args[@]}"
        return $?
    }

    function __build_test_make_check() {
        time -p make check
        return $?
    }

    function __build_test_make_test() {
        time -p make test
        return $?
    }

    function __build_test_make() {
        make -q check
        check_ret=$?

        make -q test
        test_ret=$?

        echo "$check_ret $test_ret"

        if [[ $check_ret == 1 ]]; then
            __build_test_make_check
            return $?
        elif [[ $test_ret == 1 ]]; then
            __build_test_make_test
            return $?
        else
            echo "Unknown make system! Targets 'test' and 'check' missing."
            return 1
        fi
    }

    function __build_test_python() {
        if [ -d tests ]; then
            if [ "x$pypath" == "$py2path" ]; then
                time -p pytest
                return $?
            else
                time -p pytest-3
                return $?
            fi
        fi
        time -p $pypath setup.py test
        return $?
    }

    function __build_test_maven() {
        time -p maven test
        return $?
    }

    function __build_test_nss() {
        export HOST="localhost"
        export DOMSUF="localdomain"
        export USE_64=1
        pushd tests
        time -p bash all.sh
        local ret=$?
        popd
        return $ret
    }

    function __build_test() {
        if [ -e "CMakeCache.txt" ]; then
            __build_test_ctest
            return $?
        elif [ -e "nss.gyp" ]; then
            # NSS must be higher priority than Makefile because we use gyp and
            # its build.sh script instead.
            __build_test_nss
            return $?
        elif [ -e "Makefile" ]; then
            __build_test_make
            return $?
        elif [ -e "setup.py" ]; then
            __build_test_python
            return $?
        elif [ -d "build" ]; then
            pushd build || return 1
            __build_test
            local ret=$?
            popd
            return $ret
        elif [ -d "pom.xml" ]; then
            __build_test_maven
        elif [ -d "src" ]; then
            pushd src || return 1
            __build_test
            local ret=$?
            popd
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
            return $?
        else
            echo "Unknown rpm system!"
            return 1
        fi
    }

    function __build_uncd() {
        local cpwd="$(pwd 2>/dev/null)"

        if [ "x$cpwd" != "x" ] && [ "x$cpwd" != "x$starting_dir" ]; then
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

    if [ "$do_popd" == "true" ]; then
        __build_uncd
    fi
    return 0
}
